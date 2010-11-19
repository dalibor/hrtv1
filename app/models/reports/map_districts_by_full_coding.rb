require 'fastercsv'

class Reports::MapDistrictsByFullCoding < Reports::CodedActivityReport
  include Reports::Helpers
  
  def initialize(activities, report_type)
    @codes_to_include = []
  #  [9020101, 90207].each do |e|
  #    @codes_to_include << Nsp.find_by_external_id(e)
    Code.all.each do |e|
      @codes_to_include << e if ["Mtef", "Nha", "Nsp", "Nasa"].include?(e.type.to_s)
    end
    @districts_hash = {}
    Location.all.each do |l|
      @districts_hash[l] = {}
      @districts_hash[l][:total] = 0
      @codes_to_include.each do |c|
        @districts_hash[l][c] = 0
      end
    end
    @district_proportions_hash = {} # activity => {location => proportion}
    @csv_string = FasterCSV.generate do |csv|
      csv << header()
      @activities = activities
      @report_type = report_type.constantize
      @leaves = Nsp.leaves
      @codes_to_include.each do |c|
        set_district_hash_for_code c
      end
      Location.all.each do |l|
        row csv, l, @activities, @report_type
      end
    end
  end

  def set_district_hash_for_code code
    cas = @report_type.with_activities(@activities.map(&:id)).with_code_id(code.id)
    activities = {}
    cas.each{ |ca|
      activities[ca.activity] = {}
      activities[ca.activity][:leaf_amount] = ca.sum_of_children > 0 ? 0 : ca.cached_amount
      activities[ca.activity][:amount] = ca.cached_amount
    }
    activities.each do |a, h|
      if @district_proportions_hash.key? a
        #have cached values, so speed up these proportions
        @district_proportions_hash[a].each do |loc, proportion|
          @districts_hash[loc][:total] += h[:leaf_amount] * proportion
          @districts_hash[loc][code] += h[:amount] * proportion
        end
      else
        @district_proportions_hash[a] = {}
        # We've got non-report type report type hard coding here
        # so it uses budgets
        a.budget_district_coding.each do |bd|
          proportion = bd.proportion_of_activity
          loc = bd.code
          @district_proportions_hash[a][loc] = proportion
          @districts_hash[loc][:total] += h[:leaf_amount] * proportion
          @districts_hash[loc][code] += h[:amount] * proportion
        end
      end
    end
  end
  def row(csv, loc, activities, report_type)
    #hierarchy = code_hierarchy(code)
    row = []
    row << loc.to_s.upcase
    row << n2c(@districts_hash[loc].delete(:total)) #remove key
    code_to_amt = @districts_hash[loc]
    @codes_to_include.each do |c|
      if code_to_amt[c] != 0
        row << n2c(code_to_amt[c])
      else
        row << nil
      end
    end
    csv <<  row
  end

  def header()
    row = []
    row << "District"
    row << "Total Budget"
    @codes_to_include.each do |c|
      row << c.official_name
    end
    row
  end
  def csv
    @csv_string
  end

  def add_rows csv, code
    add_code_summary_row(csv, code)
    row(csv, code, @activities, @report_type) if @districts_hash.key? code
    kids = code.children
    kids.each do |c|
      add_rows(csv, c)
    end
  end

  def add_code_summary_row csv, code
#    csv << "In NSP #{code.short_display} #{code.id} #{code.external_id} "
#    csv << code.external_id.to_s
    total_for_code = code.sum_of_assignments_for_activities(@report_type, @activities)
    if total_for_code > 0
      csv << (code_hierarchy(code) + [nil,nil, "Total Budget - "+n2c(total_for_code)]) #put total in Q1 column
    end
    #TODO merge cells[code.level:amount_column] for this code
  end

  # We've got non-report type report type hard coding here
  # so it uses budgets


  protected

  def code_hierarchy(code)
    # TODO merge all columns to the left and put row's value
    # if there is more than 5 rows in the section
    hierarchy = []
    Code.each_with_level(code.self_and_ancestors) do |e, level| # each_with_level() is faster than level()
      if e==code
        hierarchy << official_name_w_sum(e)
      else
        hierarchy << nil
      end
      #hierarchy << "#{e.external_id} - #{e.sum_of_assignments_for_activities(@report_type, @activities)}"
    end
    (Code.deepest_nesting - hierarchy.size).times{ hierarchy << nil } #append empty columns if nested higher
    hierarchy
  end

  def official_name_w_sum code
    "#{code.official_name}" # - #{n2c( code.sum_of_assignments_for_activities(@report_type, @activities) )}"
  end

end
