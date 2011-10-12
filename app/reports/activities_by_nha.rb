require 'fastercsv'

class Reports::ActivitiesByNha
  include Reports::Helpers

  def initialize(current_user)
    @activities = Activity.only_simple.canonical_with_scope.find(:all,
       :include => [:provider, :organizations, {:data_response => :organization}])

    @activities = @activities.first(10)
    @deepest_nesting  = Code.deepest_nesting
  end

  def csv
    FasterCSV.generate do |csv|
      csv << build_header
      @activities.each{|activity| build_rows(csv, activity)}
    end
  end

  private
    def build_header
      row = []
      row << "contact name"
      row << "contact position"
      row << "contact phone number"
      row << "contact main office phone number"
      row << "contact office location"
      row << 'Funding Source(s)'
      row << 'Organization type'
      row << 'Organization'
      row << 'Implementer'
      row << 'District'
      row << 'Implementer'
      row << 'Activity ID'
      row << 'Activity name'
      row << 'Activity description'
      row << 'Activity currency'
      row << 'Total Past Expenditure'
      row << 'Converted Total Past Expenditure (USD)'
      row << 'Classified Past Expenditure'
      row << 'Converted Classified Past Expenditure (USD)'
      row << "Code type"
      row << "Code sub account"
      row << "Code nha code"
      row << "Code nasa code"
      row << 'NHA/NASA Code'
      @deepest_nesting.times{ row << 'Code' }

      row
    end

    # nha and nasa only track expenditure
    def build_rows(csv, activity)
      funding_sources       = get_funding_sources(activity)
      funding_sources_total = get_funding_sources_total(activity, funding_sources, false) # for spent

      funding_sources.each do |funding_source|
        funding_source_ratio  = get_ratio(funding_sources_total, funding_source.spend_in_usd)

        row = []
        dr = activity.data_response
        row << dr.contact_name
        row << dr.contact_position
        row << dr.contact_phone_number
        row << dr.contact_main_office_phone_number
        row << dr.contact_office_location

        project = activity.project
        unless project.nil?
          row << project.in_flows.collect{|f| "#{f.from.try(:name)}(#{f.spend})"}.join(";")
        else
          row << "No FS info; project was not entered"
        end
        row << activity.organization.try(:raw_type)
        row << activity.organization.try(:name)
        row << activity.provider.try(:name)
        row << get_locations(activity)
        row << get_sub_implementers(activity)
        row << activity.id
        row << activity.name
        row << activity.description
        row << activity.currency
        row << activity.spend
        row << activity.spend_in_usd

        build_code_assignment_rows(csv, activity, row, funding_source_ratio)
      end
    end

    def build_code_assignment_rows(csv, activity, base_row, funding_source_ratio)
      cas = activity.coding_spend.leaves.
        with_amount.find(:all,  :include => :code)

      cas.each do |ca|
        codes     = ca.code.self_and_ancestors
        last_code = codes.last
        row       = base_row.dup

        row << (ca.cached_amount || 0) * funding_source_ratio
        row << ca.cached_amount_in_usd * funding_source_ratio
        row << last_code.try(:type)
        row << last_code.try(:sub_account)
        row << last_code.try(:nha_code)
        row << last_code.try(:nasa_code)
        row << get_nha_or_nasa(last_code)

        add_codes_to_row(row, codes, @deepest_nesting, :short_display)

        csv << row
      end
    end

    def get_nha_or_nasa(last_code)
      if (last_code.type == 'Nha' || last_code.type == 'Nasa')
        last_code.try(:official_name)
      else
        'n/a'
      end
    end
end
