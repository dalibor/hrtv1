module Charts::DistrictTreemaps
  extend NumberHelper
  extend Charts::HelperMethods

  class << self
    def treemap(request_id, location, code_type, activities, is_spent)
      case code_type
      when 'mtef'
        codes   = Mtef.all + Nsp.all + Nha.all + Nasa.all
        roots   = Mtef.roots
      when 'nsp'
        codes   = Nsp.all
        roots   = Nsp.roots
      when 'cost_category'
        codes = CostCategory.all
        roots = CostCategory.roots
      else
        raise "Invalid type for district treemap #{code_type}".to_yaml
      end

      coding_type = get_coding_type(code_type, is_spent)

      if is_spent
        district_type     = "CodingSpendDistrict"
        activity_value    = "spend"
      else
        district_type     = "CodingBudgetDistrict"
        activity_value    = "budget"
      end

      get_treemap_rows(roots, codes, coding_type, activities, location, district_type, activity_value, request_id).to_json
    end

    private

      def get_treemap_rows(root_codes, codes, type, activities, location, district_type, activity_value, request_id)
        # format is my value, parent value, box_area_value, coloring_value
        activities         = Activity.only_simple_activities(activities)
        code_ids           = get_all_code_ids(root_codes)
        code_assignments   = CodeAssignment.with_request(request_id).sums_by_code_id(code_ids, type.to_s, activities)
        treemap_ratios     = CodeAssignment.ratios_by_activity_id(location.id, activities.map(&:id), district_type, activity_value)
        treemap_sums       = prepare_treemap_sums(code_assignments, treemap_ratios, code_ids)

        rows           = []

        root_codes_sum = get_root_codes_sum(root_codes, treemap_sums)
        root_name = "#{n2c(root_codes_sum)}: All Codes"

        rows << [root_name, nil, root_codes_sum, 0]

        root_codes.each do |code|
          parent_display_cache = {} # code => display_value , used to connect rows
          parent_display_cache[code.parent_id] = root_name

          code.self_and_descendants.each do |c|
            sum = treemap_sums[c.id]
            get_treemap_row(c, rows, type, activities, parent_display_cache, root_codes_sum, sum) if codes.include?(c)
          end
        end

        rows
      end

      def get_treemap_row(code, rows, type, activities, treemap_parent_values, total_for_percentage, sum)
        name  = code.to_s_prefer_official

        ignore_second_parent = treemap_parent_values.empty? || treemap_parent_values.keys.include?(code.parent_id) # TODO: data problem with treemap: uncaught exception: Parent doubly defined.

        if sum > 0 && ignore_second_parent
          name_w_sum = "#{n2c(sum.fdiv(total_for_percentage)*100)}%: #{name}"
          if treemap_parent_values.values.include?(name_w_sum)
            name_w_sum = "#{n2c(sum)} (2): #{name}"
          end
          treemap_parent_values[code.id] = name_w_sum
          my_parent_treemap_value = treemap_parent_values[code.parent_id]
          rows << [name_w_sum, my_parent_treemap_value, sum, sum]
        end
      end

      def prepare_treemap_sums(treemap_sums, treemap_ratios, code_ids)
        sums = {}
        code_ids.each do |code_id|
          sums[code_id] = detect_sum(treemap_sums, treemap_ratios, code_id)
        end
        sums
      end

      def detect_sum(code_assignments, treemap_ratios, code_id)
        sum = 0

        amounts = code_assignments[code_id]
        if amounts.present?
          amounts.each do |amount|
            ratios = treemap_ratios[amount.activity_id]
            if ratios.present?
              ratio = ratios.first.ratio.to_f
              sum += amount.value.to_f * ratio
            end
          end
        end

        sum
      end
  end
end
