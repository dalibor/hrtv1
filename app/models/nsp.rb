# == Schema Information
#
# Table name: codes
#
#  id                  :integer         primary key
#  parent_id           :integer
#  lft                 :integer
#  rgt                 :integer
#  short_display       :string(255)
#  long_display        :string(255)
#  description         :text
#  created_at          :timestamp
#  updated_at          :timestamp
#  start_date          :date
#  end_date            :date
#  replacement_code_id :integer
#  type                :string(255)
#  external_id         :string(255)
#  hssp2_stratprog_val :string(255)
#  hssp2_stratobj_val  :string(255)
#  official_name       :string(255)
#

class Nsp < Code
  NSP_TYPE = 'Nsp'

  named_scope :roots, :joins => "INNER JOIN codes AS parents ON codes.parent_id = parents.id",
              :conditions => [ "codes.type = ? AND parents.type != ?", NSP_TYPE, NSP_TYPE]
#  def self.leaves
    # NSP 'leaves' are sometimes also embedded at the top of other hierarchies, so we override the default awesome_nested_set :leaves
    # e.g. 
#  end

  # Returns the array of all parents and self
  def self_and_nsp_ancestors
    nested_set_scope.scoped :conditions => [
      "type = ? AND #{self.class.quoted_table_name}.#{quoted_left_column_name} <= ? AND #{self.class.quoted_table_name}.#{quoted_right_column_name} >= ?", NSP_TYPE, left, right
    ]
  end

  # Returns an array of all parents
  def nsp_ancestors
    without_self self_and_nsp_ancestors
  end

  def self.nsp_roots_with_level
    # NSP 'roots' are embedded in other hierarchies, so we override the default awesome_nested_set :roots
    Nsp.roots.each do |nsp_root|
       puts "\n\n#{nsp_root.external_id}: #{nsp_root.short_display.first(20) + '...'}\n"
      # each_with_level() is faster than level()
      Nsp.each_with_level(nsp_root.self_and_descendants) do |o, level|
        puts "  #{level}, #{o.external_id}, #{o.short_display.first(20) + '...'} " #, #{o.code_assignments } " #.with_activities(1443)}\n"
      end
    end
  end

  def self.nsp_leaves_with_level
    # NSP 'roots' are embedded in other hierarchies, so we override the default awesome_nested_set :roots
    # NSP 'leaves' are sometimes also embedded in other hierarchies, so we override the default awesome_nested_set :leaves
    Nsp.leaves.each do |nsp|
       puts "\n\n#{nsp.external_id}: #{nsp.short_display.first(20) + '...'}\n"
      # each_with_level() is faster than level()
      Nsp.each_with_level(nsp.self_and_nsp_ancestors.reverse) do |code, level|
        puts "  #{level}, #{code.external_id}, #{code.short_display.first(20) + '...'} " #, #{o.code_assignments } " #.with_activities(1443)}\n"
      end
    end
  end

  # DataResponse.find(6533).activities
  def self.activity_report(activities)
    csv = []
    Nsp.leaves.each do |nsp_node|
      Nsp.each_with_level(nsp_node.self_and_nsp_ancestors.reverse) do |code, level| # each_with_level() is faster than level()
        #TODO - make sure always prepending the right nr of columns
        parent_nodes = []
        Nsp.each_with_level(code.nsp_ancestors) do |parent, level| # each_with_level() is faster than level()
          parent_nodes << "#{parent.external_id}"
        end
         
        # this just needs to be replaced with code.leaf_assigns_for_activities(activities)
        code.code_assignments.with_activities(activities).each do |assignment|
          row = []
          row << "#{code.external_id}"
          row << "#{code.level}"
          row << "#{code.short_display.first(20) + '...'}"
          row << "#{assignment.type}"
          row << "#{assignment.amount}"
          row << "#{assignment.cached_amount}"
          row << "#{assignment.activity_id}"
          csv << (parent_nodes + row).join(", ") + "\n"
        end
      end
    end
    csv
  end

  # leaf_assigns_for_activities in parent class
  def self.another_way_to_do_activity_report(type, activities)
    csv = []
    #right_number_of_columns = max(Nsp.leaves.level)
    Nsp.leaves.each do |nsp_node|
      Nsp.each_with_level(nsp_node.self_and_nsp_ancestors.reverse) do |code, level| # each_with_level() is faster than level()
        #TODO - make sure always prepending the right nr of columns
        # see right_number_of_columns above
        parent_nodes = []
        Nsp.each_with_level(code.nsp_ancestors) do |parent, level| # each_with_level() is faster than level()
          parent_nodes << "#{parent.external_id}"
        end

        code.leaf_assigns_for_activities(type, activities) do |assignment|
          row = []
          row << "#{code.external_id}"
          row << "#{code.level}"
          row << "#{code.short_display.first(20) + '...'}"
          row << "#{assignment.type}"
          row << "#{assignment.amount}"
          row << "#{assignment.cached_amount}"
          row << "#{assignment.sum_of_children}"
          row << "#{assignment.activity_id}"
          csv << (parent_nodes + row).join(", ") + "\n"
        end
      end
    end
    csv
  end
end


