Feature: Activity Manager can approve a code breakdown for each activity
  In order to increase the quality of information reported
  As a NGO/Donor Activity Manager
  I want to be able to approve activity splits

  Background:
    Given an organization "admin_org" exists with name: "admin_org"
      And a data_request exists with title: "dr1", organization: the organization
      And an organization "reporter_org" exists with name: "reporter_org"
      And a reporter exists with organization: the organization
      And data_response should exist with data_request: the data_request, organization: the organization
      And a project exists with name: "project1", data_response: the data_response
      And an activity exists with name: "activity1", description: "a1 description", data_response: the data_response, project: the project
      And an organization "ac_org" exists with name: "ac_org"
      And an activity_manager exists with email: "activity_manager@hrtapp.com", organization: the organization
      And organization "reporter_org" is one of the activity_manager's organizations
      And I am signed in as "activity_manager@hrtapp.com"

  @javascript
  Scenario: Approve an Activity from listing
    Given I follow "reporter_org"
    When I hover over ".js_project_row" within ".workplan"
    And wait a few moments
    And I follow "Approve Budget"
    And wait a few moments
    Then I should see "Budget Approved"

  @javascript
  Scenario: Approve an Activity
    Given I follow "reporter_org"
    And I follow "activity1"
    When I follow "Approve Budget"
    And wait a few moments
    Then I should see "Budget Approved"

  Scenario: Approve all Activities from listing
    Given an activity exists with name: "activity2", description: "a1 description", data_response: the data_response, project: the project
    And I follow "reporter_org"
    When I follow "Approve all Budgets" within ".js_approve_all_activities"
    Then I should not see "Approve all Budgets" within ".js_approve_all_activities"
    And I should see "Budget Approved"

  Scenario: Approve all Other Costs from listing
    Given an other_cost exists with name: "other_cost1", description: "oc1 description", data_response: the data_response, project: the project
    And an other_cost exists with name: "other_cost2", description: "oc2 description", data_response: the data_response, project: the project
    And I follow "reporter_org"
    When I follow "Approve all Budgets" within ".js_approve_all_other_costs"
    Then I should not see "Approve all Budgets" within ".js_approve_all_other_costs"
    And I should see "Budget Approved"

  Scenario: Approve all Other Costs with no project from listing
    Given an other_cost exists with name: "other_cost1", description: "oc1 description", data_response: the data_response
    And an other_cost exists with name: "other_cost2", description: "oc2 description", data_response: the data_response
    And I follow "reporter_org"
    When I follow "Approve all Budgets" within ".js_approve_all_other_costs_np"
    Then I should not see "Approve all Budgets" within ".js_approve_all_other_costs_np"
    And I should see "Budget Approved"
