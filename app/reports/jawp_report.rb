require 'fastercsv'

class Reports::JawpReport
  include Reports::Helpers

  attr_accessor :include_subs # could be deprecated

  def initialize(type, activities)
    @include_subs                  = false
    @is_budget                     = is_budget?(type)
    @activities                    = activities
    @code_deepest_nesting          = Code.deepest_nesting
    @cost_category_deepest_nesting = CostCategory.deepest_nesting
    @hc_implementer_splits         = ImplementerSplit.implemented_by_health_centers.
      find(:all, :select => 'activity_id, COUNT(*) AS total',
           :group => 'activity_id')

    Activity.send(:preload_associations, @activities, [:implementer_splits])
      #[{ :project => {:in_flows => :from} }, { :data_response => :organization },
       #:organizations, :provider]) # wierd selects when preloading :beneficiaries
  end

  def csv
    FasterCSV.generate(:encoding => 'u') do |csv|
      csv << build_header
      @activities.each{ |activity| build_rows(csv, activity) }
      # for debugging purposes
      # [Activity.find(8952)].each{|activity| build_rows(csv, activity)}
    end
  end

  private
    # gor_quarters methods returns values for US fiscal year (10th month)
    # otherwise it returns the values for Rwanda fiscal year
    def build_rows(csv, activity)
      if @is_budget
        amount_total          = activity.budget
        amount_total_in_usd   = activity.budget_in_usd
        is_national           = (activity.coding_budget_district.empty? ? 'yes' : 'no') # fixme
      else
        amount_total          = activity.spend
        amount_total_in_usd   = activity.spend_in_usd
        is_national           = (activity.coding_spend_district.empty? ? 'yes' : 'no') # fixme
      end
      row = []
      row << activity.project.try(:name)
      row << activity.project.try(:description).try(:gsub, /[\n\r-]+/, " ")
      row << activity.name
      row << activity.description.try(:gsub, /[\n\r-]+/, " ")
      row << get_locations(activity)
      row << activity.implementer_splits.length
      row << get_hc_sub_activity_count(activity)
      row << activity.implementer_splits.map{ |s| s.organization_name }.join(' | ')
      row << activity.organization.try(:name)
      row << get_institutions_assisted(activity)
      row << get_beneficiaries(activity)
      row << activity.id
      row << activity.currency
      row << amount_total
      row << amount_total_in_usd
      row << is_national
      build_code_assignment_rows(csv, row, activity, amount_total, amount_total_in_usd)
    end


    def build_code_assignment_rows(csv, base_row, activity, amount_total, amount_total_in_usd)
      if @is_budget
        codings               = fake_one_assignment_if_none(amount_total, amount_total_in_usd, activity.coding_budget)
        district_codings      = fake_one_assignment_if_none(amount_total, amount_total_in_usd, activity.coding_budget_district)
        cost_category_codings = fake_one_assignment_if_none(amount_total, amount_total_in_usd, activity.coding_budget_cost_categorization)
      else
        codings               = fake_one_assignment_if_none(amount_total, amount_total_in_usd, activity.coding_spend)
        district_codings      = fake_one_assignment_if_none(amount_total, amount_total_in_usd, activity.coding_spend_district)
        cost_category_codings = fake_one_assignment_if_none(amount_total, amount_total_in_usd, activity.coding_spend_cost_categorization)
      end
      parent_activity = activity
      parent_amount_total = amount_total
      parent_amount_total_in_usd = amount_total_in_usd
      if activity.implementer_splits.empty? or !@include_subs
        implementer_splits = [activity]
        use_sub_activity_district_coding = false
      else
        implementer_splits = activity.implementer_splits
         if @is_budget
           use_sub_activity_district_coding =
              parent_activity.implementer_splits_each_have_defined_districts?("CodingBudgetDistrict")
         else
           use_sub_activity_district_coding =
              parent_activity.implementer_splits_each_have_defined_districts?("CodingSpendDistrict")
         end
      end

      funding_sources = activity.funding_streams
      funding_sources_total = 0
      funding_sources.each do |fs|
        if @is_budget
          funding_sources_total += fs[:budget] if fs[:budget]
        else
          funding_sources_total += fs[:spend] if fs[:spend]
        end
      end

      # edge case that handles bad quality data e.g. funding sources
      # that dont have amounts specified for them
      # TODO move this into helper in get_funding_sources for all reports!
      if funding_sources_total == 0
        funding_sources = [{:ufs => nil, :fa => nil, :spend => 1, :budget => 1}]
        funding_sources_total = 1
      end

      coding_with_parent_codes = get_coding_only_nodes_with_local_amounts(codings)
      cost_category_coding_with_parent_codes = get_coding_only_nodes_with_local_amounts(cost_category_codings)

      implementer_splits.each do |activity|
        break_out = false
        if activity != parent_activity
          if @is_budget #to get budget or past expenditure district codings and check this sub_activity has nonzero budget or spend
            if activity.budget?
              district_codings = activity.coding_budget_district
              amount_total = activity.budget
              amount_total_in_usd = parent_amount_total_in_usd * activity.budget / parent_activity.budget
            else
              break_out = true
            end
          else
            if activity.spend?
              district_codings = activity.coding_spend_district
              amount_total = activity.spend
              amount_total_in_usd = parent_amount_total_in_usd * activity.spend / parent_activity.spend
            else
              break_out = true
            end
          end
        end
        break if break_out

        cost_category_coding_with_parent_codes.each do |cost_category_ca_coding|
          cost_category_coding = cost_category_ca_coding[0]
          cost_category_codes  = cost_category_ca_coding[1]

          funding_sources.each do |funding_source|
            coding_with_parent_codes.each do |ca_codes|
              district_codings.each do |district_coding|
                ca                    = ca_codes[0]
                codes                 = ca_codes[1]
                last_code             = codes.last
                row                   = base_row.dup
                funding_source_amount =  @is_budget ?
                  funding_source[:budget] : funding_source[:spend]

                funding_source_amount =  0 if funding_source_amount.nil?
                ratio = get_ratio(parent_amount_total, ca.amount_not_in_children) *
                  get_ratio(use_sub_activity_district_coding ? amount_total : parent_amount_total, district_coding.amount_not_in_children) *
                  get_ratio(parent_amount_total, cost_category_coding.amount_not_in_children) *
                  get_ratio(funding_sources_total, funding_source_amount)
                amount = (amount_total || 0) * ratio
                if activity.class == OtherCost
                  prov = "Administration - #{activity.data_response.organization.raw_type}"
                  prov_type = "Admin"
                elsif activity.provider.nil?
                  prov = "Unspecified"
                  prov_type = "Unspecified"
                else
                  prov = activity.provider.name
                  prov_type = activity.provider.raw_type
                end
                row << activity.possible_duplicate?
                row << prov
                row << prov_type
                row << funding_source[:ufs].try(:name)
                row << funding_source[:ufs].try(:raw_type)
                row << funding_source[:fa].try(:name)
                row << funding_source[:fa].try(:raw_type)
                row << amount
                row << ratio
                row << amount_total_in_usd * ratio
                obj = codes_cache[ca.code_id].try(:hssp2_stratobj_val)
                if obj.blank?
                  obj = codes_cache[ca.code_id].try(:type) != "OtherCostCode" ? "Too Vague" : "Other Cost"
                end
                prog = codes_cache[ca.code_id].try(:hssp2_stratprog_val)
                if prog.blank?
                  prog = codes_cache[ca.code_id].try(:type) != "OtherCostCode" ? "Too Vague" : "Other Cost"
                end
                row << obj
                row << prog
                add_codes_to_row(row, codes, @code_deepest_nesting, :short_display)
                add_codes_to_row(row, codes, @code_deepest_nesting, :official_name)
                row << last_code.try(:short_display)
                row << last_code.try(:official_name)
                row << last_code.try(:type)
                row << last_code.try(:sub_account)
                row << last_code.try(:nha_code)
                row << last_code.try(:nasa_code)
                row << codes_cache[district_coding.code_id].try(:short_display)
                add_codes_to_row(row, cost_category_codes, @cost_category_deepest_nesting, :short_display)
                csv << row
              end
            end
          end
        end
      end #implementer_splits
    end

    def build_header
      amount_type = @is_budget ? 'Current Budget' : 'Past Expenditure'
      row = []
      row << "Project Name"
      row << "Project Description"
      row << "Activity Name"
      row << "Activity Description"
      row << "Districts"
      row << "# of implemeneters"
      row << "# of facilities implementing"
      row << "Implementers"
      row << "Organization"
      row << "Institutions Assisted"
      row << "Beneficiaries"
      row << "ID"
      row << "Currency"
      # values below given through build_code_assignment_rows
      row << "Total #{amount_type}"
      row << "Converted #{amount_type} (USD)"
      row << "National?"
      row << "Possible Duplicate?"
      row << "Implementer"
      row << "Implementer Type"
      row << 'Funding Source'
      row << 'Funding Source Type'
      row << 'Financing Agent'
      row << 'Financing Agent Type'
      row << "Classified #{amount_type}"
      row << "Classified #{amount_type} Percentage"
      row << "Converted Classified #{amount_type} (USD)"
      row << "HSSPII Strat obj"
      row << "HSSPII Strat prog"
      @code_deepest_nesting.times{ row << "Code" }
      @code_deepest_nesting.times{ row << "Official Code" }
      row << "Lowest level Code"
      row << "Lowest level Official Code"
      row << "Code type"
      row << "Code sub account"
      row << "Code nha code"
      row << "Code nasa code"
      row << "District"
      @cost_category_deepest_nesting.times{ row << "Input" }
      row
    end

    def get_fake_ca
      @fake ||= CodeAssignment.new
    end

    def fake_one_assignment_if_none(amount_total, amount_total_in_usd, codings)
      fake_ca = get_fake_ca
      fake_ca.cached_amount = amount_total # update the fake ca with current activity amount
      fake_ca.cached_amount_in_usd = amount_total_in_usd
      codings.empty? ? [fake_ca] : codings
    end

    def get_institutions_assisted(activity)
      activity.organizations.map{|o| o.name}.join(' | ')
    end

    def get_beneficiaries(activity)
      activity.beneficiaries.map{|o| o.short_display}.join(' | ')
    end

    def get_hc_sub_activity_count(activity)
      @hc_implementer_splits.detect{|sa| sa.activity_id == activity.id}.try(:total) || 0
    end
end
