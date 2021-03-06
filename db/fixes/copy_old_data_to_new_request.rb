# Copies old data to a new request, and zeroes out amounts

def zero_out_everything(project)
  project.budget =
    project.spend =
    project.spend_q1 =
    project.spend_q1         =
    project.spend_q2         =
    project.spend_q3         =
    project.spend_q4         =
    project.spend_q4_prev    =
    project.budget_q1        =
    project.budget_q2        =
    project.budget_q3        =
    project.budget_q4        =
    project.budget_q4_prev   =
    #project.budget2          =
    #project.budget3          =
    #project.budget4          =
    #project.budget5          =
    nil

  project.comments_count = 0 # has default of 0 - must preserve

  project.normal_activities.each do |a|
    a = zero_out_activity(a)
  end

  project.other_costs.each do |a|
    a = zero_out_activity(a)
  end

  project.funding_flows.each do |f|
    f = zero_out_flow(f)
  end

  project.funding_streams.each do |f|
    f = zero_out_stream(f)
  end

  project
end

def zero_out_activity(activity)
  activity.budget =
    activity.spend_q1                              =
    activity.spend_q2                              =
    activity.spend_q3                              =
    activity.spend_q4                              =
    activity.spend                                 =
    activity.spend_q4_prev                         =
    activity.approved                              =
    activity.budget_q1                             =
    activity.budget_q2                             =
    activity.budget_q3                             =
    activity.budget_q4                             =
    activity.budget_q4_prev                        =
    activity.comments_count                        =
    #activity.budget2                               =
    #activity.budget3                               =
    #activity.budget4                               =
    #activity.budget5                               =
    activity.am_approved                           =
    activity.am_approved_date                      =
    nil

  # thse have default of 0 - must preserve
  activity.comments_count =
    activity.CodingBudget_amount                   =
    activity.CodingBudgetCostCategorization_amount =
    activity.CodingBudgetDistrict_amount           =
    activity.CodingSpend_amount                    =
    activity.CodingSpendCostCategorization_amount  =
    activity.CodingSpendDistrict_amount            =
    activity.spend_in_usd                          =
    activity.budget_in_usd                         =
    activity.ServiceLevelBudget_amount             =
    activity.ServiceLevelSpend_amount              =
    0

  activity.code_assignments.each do |ca|
    save_assignment_ratio(ca)
    zero_out_assignment(ca)
  end

  activity.implementer_splits.each do |sa|
    zero_out_activity(sa)
  end

  activity.funding_sources.each do |f|
    zero_out_funding_source(f)
  end

  activity
end

def save_assignment_ratio(ca)
  ca.percentage = ca.proportion_of_activity * 100
end

def zero_out_assignment(ca)
  ca.amount                 =
   nil

  # dont zero out percentage. might prove useful

  ca.cached_amount          =
    ca.sum_of_children      =
    ca.cached_amount_in_usd =
    0

  ca
end

def zero_out_flow(flow)
  flow.budget               =
    flow.spend_q1           =
    flow.spend_q2           =
    flow.spend_q3           =
    flow.spend_q4           =
    flow.spend              =
    flow.spend_q4_prev      =
    flow.budget_q1          =
    flow.budget_q2          =
    flow.budget_q3          =
    flow.budget_q4          =
    flow.budget_q4_prev     =
    nil
  flow
end

def zero_out_stream(funding_stream)
  funding_stream.budget               =
  funding_stream.budget_in_usd               =
    funding_stream.spend              =
    funding_stream.spend_in_usd              =
    nil
  funding_stream
end

def zero_out_funding_source(fs)
  fs.budget = fs.spend = 0
  fs
end

def save_cloned_activity(a, zeroed_project, new_response)
  a.project = zeroed_project
  a.data_response = new_response
  a.save(false)
end


## disable callbacks for performance
Activity.before_save.clear
Activity.before_update.clear
Activity.after_save.clear
Activity.after_destroy.clear

Project.before_save.clear
Project.before_update.clear
Project.after_save.clear
Project.after_destroy.clear

CodeAssignment.before_save.clear
CodeAssignment.before_update.clear
CodeAssignment.after_save.clear
CodeAssignment.after_destroy.clear

#time = Benchmark.measure do # debug
  old_request = DataRequest.find_by_title 'FY2010 Workplan and FY2009 Expenditures'
  new_request = DataRequest.find_by_title '2010 Expenditures and 2011 Budget'

  total = Project.count
  count = 0

  unless new_request
    puts "WARNING: Cant find new request!! '2010 Expenditures and 2011 Budget'"
    exit true
  end

  puts 'Copying all data to new request!'

  Organization.all.each do |org|
  #Organization.find_all_by_name("CAMERWA - Central d\'achat des medicaments du Rwanda / Central Drug Purchasing Agency for Rwanda").each do |org|
  #Organization.find_all_by_name("CCHIPs").each do |org|
    puts "Org: #{org.name}"

    old_response = org.responses.find_by_data_request_id(old_request.id)
    new_response = org.responses.find_by_data_request_id(new_request.id)
    if new_response
      puts "=> updating response #{new_response.id}"

      puts "  Projects: #{new_response.projects.count} #{new_response.projects.empty?}"

      unless new_response.projects.empty?
        puts "  SKIPPING: projects already exist for this org in the new response!"
      else

        #### projects & activities
        old_response.projects.each do |project|
          count += 1
          puts "  => Project #{count} of #{total}: (#{project.id}), #{project.name}"
          cloned_project = project.deep_clone
          zeroed_project = zero_out_everything(cloned_project)
          zeroed_project.data_response = new_response
          zeroed_project.save(false)

          zeroed_project.funding_flows.each do |f|
            f.save(false)
          end

          zeroed_project.normal_activities.each do |a|
            save_cloned_activity(a, zeroed_project, new_response)
          end

          zeroed_project.other_costs.each do |a|
            save_cloned_activity(a, zeroed_project, new_response)
          end
        end

        ###OC's without project
        new_response.other_costs = old_response.other_costs.without_a_project.collect { |obj| obj.deep_clone }

        new_response.other_costs.each do |oc|
          oc = zero_out_activity(oc)
          oc.data_response = new_response
          oc.save(false)
        end
      end
    else
      puts "=> WARN!: new response doesn't already exist. Something is wrong."
    end
  end
#end # debug
#puts "\n=> Done! (#{time.to_s})" #debug
puts "\n=> Done!"

