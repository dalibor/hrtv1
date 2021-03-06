Feature: Admin can approve a code breakdown for each activity
  In order to increase the quality of information reported
  As an admin
  I want to be able to approve activity splits via the admin data response review screen

  Background:
    Given an organization exists with name: "UNAIDS"
      And a data_request exists with title: "Req1", organization: the organization
      And an organization exists with name: "WHO"
      And a data_response should exist with data_request: the data_request, organization: the organization
      And a project exists with name: "TB Treatment Project", data_response: the data_response
      And an activity exists with name: "TB Drugs procurement", data_response: the data_response, project: the project
      And a mtef_code exists with short_display: "Mtef code"
      And a coding_budget exists with code: the mtef_code, activity: the activity

    # NB: this scenario will only work for 1 activity, 1 classification
    @javascript @wip
    Scenario: Approve a budget coding breakdown
      Given I am signed in as a sysadmin
      When I go to the admin review data response page for organization "WHO", request "Req1"
        And I click element "#project_details"
        And I click element ".project .descr"
        And I click element "#projects .activity_details"
        And I click element "#projects .activity .descr"
      Then I should see "Approved?"

      When I check "approve_activity"
        And wait a few moments
        And I go to the admin review data response page for organization "WHO", request "Req1"
        And I click element "#project_details"
        And I click element ".project .descr"
        And I click element "#projects .activity_details"
        And I click element "#projects .activity .descr"
      Then the "approve_activity" checkbox should be checked
