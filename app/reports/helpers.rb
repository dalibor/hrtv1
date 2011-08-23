module Reports::Helpers
  include NumberHelper # gives n2c method
  include StringCleanerHelper # gives h method
  extend ActiveSupport::Memoizable

  def get_coding_with_parent_codes(codings)
    coding_with_parent_codes = []
    coded_codes = codings.collect{|ca| codes_cache[ca.code_id]}

    real_codings  = codings.select do |ca|
      code = codes_cache[ca.code_id]
      (ca.amount.present? || ca.percentage.present?) &&
      code && lowest_level_code?(code, coded_codes)
    end

    real_codings.each do |ca|
      coding_with_parent_codes << [ca, ca.code.self_and_ancestors]
    end

    coding_with_parent_codes
  end

  # replacing method above, leaving above in case referenced elsewhere
  # and what it returns is what should be used for a report
  # TODO: refactor methods here into code assignment or coding class
  def get_coding_only_nodes_with_local_amounts(codings)
    if codings.size == 1 && codings.first.code_id.nil?
      #coding was faked, just return this correctly
      #return [[codings.first, ["No Code Specified"]]]
    end
    coding_with_parent_codes = []
    coded_codes = codings.collect{|ca| codes_cache[ca.code_id]}

    real_codings  = codings.select do |ca|
      code = codes_cache[ca.code_id]
      (ca.amount.present? || ca.percentage.present?) &&
      code && ca.has_amount_not_in_children?
    end

    real_codings.each do |ca|
      coding_with_parent_codes << [ca, ca.code.self_and_ancestors]
    end

    # TODO FIX BUG, sometimes this returns an [] when codings is non-empty
    # should NEVER have code assignments which have no real codings
    # raise codings.to_yaml if coding_with_parent_codes.size == 0
    coding_with_parent_codes
  end

  def codes_cache
    return @codes_cache if @codes_cache

    @codes_cache = {}
    Code.all.each do |code|
      @codes_cache[code.id] = code
    end

    return @codes_cache
  end

  def code_descendants_cache
    return @code_descendants_cache if @code_descendants_cache

    @code_descendants_cache = {}
    Code.all.each do |code|
      @code_descendants_cache[code.id] = code.descendants
    end

    return @code_descendants_cache
  end

  # TODO refactor methods having to do with code assignments
  # traversal, and values, back into the model for them
  def lowest_level_code?(code, coded_codes)
    llcode = true

    # check if any of the descendants of the code is in the code assignments
    descendants = code_descendants_cache[code.id]
    if descendants.present?
      descendants.each do |dcode|
        if coded_codes.include?(dcode)
          llcode = false
          break
        end
      end
    end

    return llcode
  end


  def funding_source_name(activity)
    get_funding_sources(activity).map{|f| f.from.try(:name)}.uniq.join(', ')
  end

  def get_funding_sources(activity)
    #TODO fake one if none so works correctly, w name of Not Entered
    #TODO handle case with one funding source with 0 amts in it, if 1 then assume all there
    # TODO take logic from jawp report that replaces bad funding sources, marked with a TODO
    funding_sources = []
    if activity.project
      activity.project.in_flows.each do |funding_source|
        funding_sources << funding_source
      end
    end
    funding_sources
  end
  memoize :get_funding_sources

  def get_sub_implementers(activity)
    activity.sub_implementers.map{|si| si.name}.join(' | ')
  end

  def get_locations(activity)
    activity.locations.map{|l| l.short_display}.join(' | ')
  end

  def add_codes_to_row(row, codes, deepest_nesting, attr)
    last_code_found = 0
    deepest_nesting.times do |i|
      code = codes[i]
      if code
        row << codes_cache[code.id].try(attr)
        last_code_found = i
      else
        if last_code_found == i - 1
          row << "Not Disaggregated Further"
        else
          row << "At Level Above"
        end
      end
    end
  end

  def get_funding_sources_total(activity, funding_sources, is_budget)
    method = is_budget ? :budget_in_usd : :spend_in_usd
    funding_sources.inject(0){|acc, fs| acc + fs.send(method)}
  end

  def get_ratio(amount_total, amount)
    amount_total && amount_total > 0 ? amount / amount_total : 0
  end

  def provider_name(activity)
    activity.provider ? "#{h activity.provider.name}" : " "
  end

  def get_beneficiaries
    Beneficiary.find(:all, :select => 'short_display').map{|code| code.short_display}.sort
  end

  # if [Activity].include?(activity.class) -> type IS NULL
  def root_activities(request)
    Activity.with_request(request).find(:all, :conditions => "type IS NULL AND activity_id IS NULL")
  end

  def number_of_health_centers(activity)
    health_centers = activity.sub_activities.implemented_by_health_centers.count
    health_centers > 0 ? health_centers : nil
  end

  def activity_description(activity)
    if activity.name
      val = "#{activity.name.chomp}"
      val += " - #{activity.description.chomp}" if activity.description
      val
    else
      activity.description ? activity.description.chomp : nil
    end
  end

  def official_name_w_sum(code)
    code.official_name ? "#{code.official_name}" : "#{code.short_display}"
  end

  def add_all_codes_hierarchy(row, code)
    counter = 0
    Code.each_with_level(code.self_and_ancestors) do |other_code, level|
      counter += 1
      row << (code == other_code ? official_name_w_sum(other_code) : nil)
    end
    (Code.deepest_nesting - counter).times{ row << nil }
  end

  def add_nsp_codes_hierarchy(row, code)
    counter = 0
    Nsp.each_with_level(code.self_and_nsp_ancestors) do |other_code, level|
      counter += 1
      row << (code == other_code ? official_name_w_sum(other_code) : nil)
    end
    (Nsp.deepest_nesting - counter).times{ row << nil }
  end

  def cache_activities(code_assignments)
    activities = {}
    code_assignments.each do |ca|
      activities[ca.activity] = {}
      activities[ca.activity][:leaf_amount] = (ca.sum_of_children == 0 ? ca.cached_amount_in_usd : 0)
      activities[ca.activity][:amount] = ca.cached_amount_in_usd
    end
    activities
  end

  def provider_fosaid(activity)
    activity.provider ? "#{h activity.provider.fosaid}" : " "
  end

  def is_activity(activity)
    activity.class == SubActivity ? "yes" : ""
  end

  def parent_activity_budget(activity)
    activity.class == SubActivity ? activity.activity.budget_in_usd : ""
  end

  def parent_activity_spend(activity)
    activity.class == SubActivity ? activity.activity.spend_in_usd : ""
  end

  def is_budget?(type)
    if type == :budget
      true
    elsif type == :spent
      false
    else
      raise "Invalid type #{type}".to_yaml
    end
  end

  def preload_district_associations(activities, is_budget)
    if is_budget
      Activity.send(:preload_associations, activities,
                    {:coding_budget_district => :activity})
    else
      Activity.send(:preload_associations, activities,
                    {:coding_spend_district => :activity})
    end
  end
end
