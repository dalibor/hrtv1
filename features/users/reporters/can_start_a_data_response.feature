Feature: Reporter can start a data response
  In order to enter data
  As a reporter
  I want to be able to start a data response


  Scenario: Reporter can start a data response
    Given an organization exists with name: "Organization 1"
      And a data_request exists with title: "Request 1"
      And a reporter exists with username: "reporter", organization: the organization
      And I am signed in as "reporter"
    When I follow "Dashboard"
      And I follow "Respond"
      And I select "Request 1" from "Data Request"
      And I fill in "Start of Fiscal Year" with "2011-01-01"
      And I fill in "End of Fiscal Year" with "2011-12-31"
      And I select "Rwandan Franc (RWF)" from "Default Currency"
      And I fill in "Contact name" with "bobby"
      And I fill in "Contact position" with "manager"
      And I fill in "Phone number" with "2384348347"
      And I fill in "Office number" with "23452345325"
      And I fill in "Office location" with "1 icecream road"
      And I press "Begin Response"
    Then I should see "Your response was successfully created."
