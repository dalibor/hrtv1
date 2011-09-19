Given /^a project$/ do
  @project = Factory(:project)
end

Given /^a reporter "([^"]*)" with email "([^"]*)" and password "([^"]*)"$/ do | name, email, password|
@user = Factory(:reporter,
                :full_name             => name,
                :email                 => email,
                :password              => password,
                :password_confirmation => password)
end

Given /^an activity manager "([^"]*)" with email "([^"]*)" and password "([^"]*)"$/ do | name, email, password|
@user = Factory(:activity_manager,
                :full_name             => name,
                :email                 => email,
                :password              => password,
                :password_confirmation => password)
end

Given /^I am signed in as "([^"]*)"$/ do |email|
  steps %Q{
    When I go to the login page
    When I fill in "Email" with "#{email}"
    And  I fill in "Password" with "password"
    And  I press "Sign in"
  }
end

Given /^I am signed in as a reporter$/ do
  steps %Q{
    Given a reporter "reporter@hrtapp.com" in organization "Reporter Org"
    And I am signed in as "reporter@hrtapp.com"
  }
end

Given /^I am signed in as a member$/ do
  steps %Q{
    Given I am signed in as a reporter
  }
end

Given /^I am signed in as an activity manager$/ do
  steps %Q{
    Given an activity manager "activity_manager@hrtapp.com" in organization "AM Org"
    Given I am signed in as "activity_manager@hrtapp.com"
  }
end

Given /^I am signed in as a sysadmin$/ do
  steps %Q{
    Given a sysadmin "sysadmin@hrtapp.com" in organization "Sysadmin Org"
    Given I am signed in as "sysadmin@hrtapp.com"
  }
end

Given /^a reporter "([^"]*)" in organization "([^"]*)"$/ do |email, org_name|
  @organization = Factory(:organization, :name => org_name)
  @user = Factory(:reporter,
                  :email => email || 'reporter@hrtapp.com',
                  :password => 'password',
                  :password_confirmation => 'password',
                  :organization => @organization)
end

Given /^an activity manager "([^"]*)" in organization "([^"]*)"$/ do |email, org_name|
  @organization = Factory(:organization, :name => org_name)
  @user = Factory(:activity_manager,
                  :email                 => email || 'activity_manager@hrtapp.com',
                  :password              => 'password',
                  :password_confirmation => 'password',
                  :organization          => @organization)

end

Given /^a sysadmin "([^"]*)" in organization "([^"]*)"$/ do |email, org_name|
  @organization = Factory(:organization, :name => org_name)
  @user = Factory(:admin,
                  :email                 => email || 'sysadmin@hrtapp.com',
                  :password              => 'password',
                  :password_confirmation => 'password',
                  :organization          => @organization)

end

Then /^debug$/ do
  $page = page
  debugger
end

Then /^I should see the main nav tabs$/ do
  steps %Q{
    Then I should see "Home"
    Then I should see "Projects"
    Then I should see "Reports"
    Then I should see "Help"
  }
end

Then /^I should see the "([^"]*)" tab is "([^"]*)"/ do |text, class_name|
  steps %Q{
    Then I should see "#{text}" within "li.#{class_name}"
  }
end

Then /^I should see the visitors header$/ do
  steps %Q{
    Then I should see "Have an account?" within "div#admin"
    And I should see "Sign in" within "div#admin"
  }
end

Then /^I should see the reporters admin nav$/ do
  steps %Q{
    Then I should see "My Profile" within "div#admin"
    Then I should see "Sign Out" within "div#admin"
  }
end

Then /^I should see the common footer$/ do
  steps %Q{
    Then I should see "Help" within "div#footer"
    Then I should see "Contact" within "div#footer"
    Then I should see "About" within "div#footer"
  }
end

# use this when you need to match the EXACT value of a field (vs the "should contain" matcher)
Then /^the "([^"]*)" field(?: within "([^"]*)")? should equal "([^"]*)"$/ do |field, selector, value|
  with_scope(selector) do
    field = find_field(field)
    field_value = (field.tag_name == 'textarea') ? field.text : field.value
    if field_value.respond_to? :should
      field_value.should == value
    else
      assert_equal(value, field_value)
    end
  end
end

def field_id(code_name)
  code = Code.find_by_short_display(code_name)
  return "activity_updates_#{code.id}_percentage"
end

# band aid fix
Given /^a data response to "([^"]*)" by "([^"]*)"$/ do |request, org|
  @response = Factory(:data_response,
                      :data_request => DataRequest.find_by_title(request),
                      :organization => Organization.find_by_name(org))
end

Then /^wait a few moments$/ do
  sleep 4
end

When /^I wait until "([^"]*)" is visible$/ do |selector|
  page.has_css?("#{selector}", :visible => true)
end


Given /^a basic org \+ reporter profile, signed in$/ do
  steps %Q{
    Given a data_request exists with title: "Req1"
    And an organization exists with name: "UNDP"
    And a reporter exists with email: "reporter@hrtapp.com", organization: the organization
    And I am signed in as "reporter@hrtapp.com"
  }
end

Given /^a basic org "([^"]*)" \+ reporter profile, with data response to "([^"]*)"$/ do |org, request|
  steps %Q{
    Given a data_request exists with title: "#{request}"
    And an organization exists with name: "#{org}"
    And a data_response should exist with data_request: the data_request, organization: the organization
    And a reporter exists with email: "reporter@hrtapp.com", organization: the organization, current_response: the data_response
    And a project exists with name: "project1", data_response: the data_response
    And an activity exists with name: "activity1", data_response: the data_response, project: the project
  }
end

Given /^a basic org "([^"]*)" \+ reporter profile, with data response to "([^"]*)", signed in$/ do |org, request|
  steps %Q{
    Given a basic org "UNDP" + reporter profile, with data response to "Req1"
    And I am signed in as "reporter@hrtapp.com"
  }
end

Given /^a basic org \+ reporter profile, with data response$/ do
  steps %Q{
    Given a basic org "UNDP" + reporter profile, with data response to "Req1"
  }
end

Given /^a basic org \+ reporter profile, with data response, signed in$/ do
  steps %Q{
    Given a basic org + reporter profile, with data response
    And I am signed in as "reporter@hrtapp.com"
  }
end

Given /^location "([^"]*)" for activity "([^"]*)"$/ do |location_name, activity_name|
  activity = Activity.find_by_name(activity_name)
  location = Location.find_by_short_display(location_name)
  activity.locations << location
end

Then /^I can manage the comments$/ do
  steps %Q{
    When I click element "#project_details"
    And I click element "#projects .project .descr"
    And I click element "#projects .activity_details"
    And I click element "#projects .activity .descr"
    And I click element "#projects .activity .comment_details"
    And I follow "+ Add Comment" within ".activity"
    And I fill in "Title" with "comment title"
    And I fill in "Comment" with "comment body"
    And I press "Create Comment"
    Then I should see "comment title"
    And I should see "comment body"
    When I follow "Edit" within "#projects .activity .resources"
    And I fill in "Title" with "new comment title"
    And I fill in "Comment" with "new comment body"
    And I press "Update Comment"
    Then I should see "new comment title"
    And I should see "new comment body"
    When I confirm the popup dialog
    And I follow "Delete" within "#projects .activity .resources"
    Then I should not see "new comment title"
    And I should not see "new comment body"
  }
end

Then /^I should see tabs for comments,projects,non-project activites$/ do
  steps %Q{
    Then I should see "Comments" within the selected data response sub-tab
    When I click element "#data_response_sub_tabs ul li a#project_details"
    Then I should see "Projects" within the selected data response sub-tab
    When I click element "#data_response_sub_tabs ul li a.activity_details"
    Then I should see "Activities without a Project" within the selected data response sub-tab
    When I click element "#data_response_sub_tabs ul li a.comment_details"
    Then I should see "Comments" within the selected data response sub-tab
  }
end

Then /^I should see tabs for comments,activities,other costs$/ do
  steps %Q{
    When I click element "#data_response_sub_tabs > ul:first-child li a#project_details"
    And I click element ".project .descr"
    Then I should see "Comments" within the selected project sub-tab
    When I click element ".project_sub_tabs ul li a.activity_details"
    Then I should see "Activities" within the selected project sub-tab
    When I click element ".project_sub_tabs ul li:last a.activity_details"
    Then I should see "Other Costs" within the selected project sub-tab
    When I click element ".project_sub_tabs ul li a.comment_details"
    Then I should see "Comments" within the selected project sub-tab
  }
end

Then /^I should see tabs for comments,sub-activities when activities already open$/ do
  steps %Q{
    When I click element "#data_response_sub_tabs > ul:first-child li a#project_details"
    And I click element ".project_sub_tabs ul li a.activity_details"
    And I click element ".activities .activity.entry_header"
    Then I should see "Comments" within the selected activity sub-tab
    When I click element ".activity_sub_tabs ul li:last a"
    Then I should see "Implementers" within the selected activity sub-tab
    When I click element ".activity_sub_tabs ul li:first"
    Then I should see "Comments" within the selected activity sub-tab
  }
end

Then /^I should see tabs for comments,sub-activities$/ do
  steps %Q{
    When I click element "#data_response_sub_tabs > ul:first-child li a#project_details"
    And I click element ".project .descr"
    And I click element ".project_sub_tabs ul li a.activity_details"
    And I click element ".activities .activity.entry_header"
    Then I should see "Comments" within the selected activity sub-tab
    When I click element ".activity_sub_tabs ul li:last a"
    Then I should see "Implementers" within the selected activity sub-tab
    When I click element ".activity_sub_tabs ul li:first"
    Then I should see "Comments" within the selected activity sub-tab
  }
end

Then /^page should have css "([^"]*)"$/ do |selector|
  page.should have_css(selector)
end

Then /^page should not have css "([^"]*)"$/ do |selector|
  page.should_not have_css(selector)
end

Then /^page should have selector "([^"]*)"$/ do |selector|
  page.find(selector).should be_present
end

Then /^page should not have selector "([^"]*)"$/ do |selector|
  page.find(selector).should_not be_present
end

Then /^column "([^"]*)" row "([^"]*)" should have text "([^"]*)"$/ do |column, row, text|
  page.find("table tbody tr[#{row}] td[#{column}]").text.should == text
end

Then /^I drill down to Reports->Districts->"([^"]*)"->"([^"]*)"$/ do |location, activity|
  steps %Q{
    And I follow "Reports"
    And I follow "Review District Expenditures and Current Budgets"
    And I follow "#{location}"
    And I follow "View all Activities"
    And I follow "#{activity}"
  }
end

Then /^I should see a District-Location-Activity report for "([^"]*)"$/ do |activity|
  steps %Q{
    Then I should see "#{activity}"
    And I should see "Proportion Expenditure"
    And I should see "Proportion Current Budget"
    And I should see "NSP Expenditure"
    And I should see "NSP Current Budget"
  }
end

Then /^I should see "([^"]*)" is "([^"]*)"$/ do |label, text|
  page.find("##{label} label").text.should == text
end

Given /^the latest response for "([^"]*)" is submitted$/ do |org_name|
  @organization = Organization.find_by_name(org_name)
  @response = @organization.latest_response
  @response.state = 'submitted'
  @response.save!
end

Then /^I should receive a csv file(?: "([^"]*)")?/ do |file|
  result = page.response_headers['Content-Type'].should == "text/csv; charset=iso-8859-1; header=present"
  if result
    result = page.response_headers['Content-Disposition'].should =~ /#{file}/
  end
  result
end

When /^I hover over "([^"]*)"(?: within "([^"]*)")?$/ do |element, selector|
  with_scope(selector) do
    page.execute_script("$('#{element}').mouseover();")
  end
end

Given /^now is "([^"]*)"$/ do |time|
  Timecop.freeze DateTime.parse(time)
end

When /^I confirm the js popup$/ do
  page.driver.browser.switch_to.alert.accept
end

When /^I dismiss the js popup$/ do
  page.driver.browser.switch_to.alert.dismiss
end

When /^I run delayed jobs$/ do
  Delayed::Job.all.each do |job|
    job.payload_object.perform
    job.destroy
  end
end

When /^I refresh the page$/ do
  visit [ current_path, page.driver.last_request.env['QUERY_STRING'] ].reject(&:blank?).join('?')
end

Given /^#{capture_model} state is: "([^"]*)"$/ do |name, state|
  response = find_model!(name)
  response.state = state
  response.save!
end

