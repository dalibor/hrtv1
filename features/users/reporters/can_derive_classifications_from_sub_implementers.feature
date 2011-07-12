Feature: Reporter can derive classifications from sub implementers
  In order to save time entering values
  As a reporter
  I want to be able to use derived classifications from sub implementers

  Background:
    Given a donor exists with name: "donor"
      And a ngo exists with name: "ngo"
      And a provider exists with name: "implementer"
      And a location exists with short_display: "Location1"
      And the location is one of the provider's locations

      And a data_request exists with organization: the donor, title: "data_request1"
      And a data_response should exist with organization: the ngo, data_request: the data_request
      And a project exists with data_response: the data_response
      And a funding_flow exists with data_response: the data_response, from: the donor, to: the ngo, budget: "10", spend: "10"
      And a funding_flow exists with data_response: the data_response, from: the ngo, to: the provider, budget: "7", spend: "7"
      And a activity exists with name: "activity1", budget: "100", spend: "100", provider: the ngo, data_response: the data_response, project: the project
      And a sub_activity exists with activity: the activity, provider: the provider, data_response: the data_response, budget: "55", spend: "55"

      And a reporter exists with email: "reporter@hrtapp.com", organization: the ngo, current_response: the data_response
      And I am signed in as "reporter@hrtapp.com"
      And I follow "data_request1"
      And I follow "Projects"
      And I follow "activity1"

    Scenario: Use budget classifications derived from sub implementers
      When I press "Save & Classify >"
        And I follow "Budget"
        And I follow "Locations"
        #And I follow "Use budget classifications derived from sub implementers"
        And I follow "Derive classification"
      Then the "Location1" field should contain "55.00"

    Scenario: Use spend classifications derived from sub implementers
      When I press "Save & Classify >"
        And I follow "Expenditure"
        And I follow "Locations"
        #And I follow "Use expenditure classifications derived from sub implementers"
        And I follow "Derive classification"
      Then the "Location1" field should contain "55.00"
