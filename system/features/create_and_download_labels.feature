Feature: Create and download labels

Scenario: Create and download labels
Given I am logged-in into backend with location WAREHOUSE_2

When I go to labels
And I click "Crear nueva"
And I click "Bajar"
And I go to labels
Then I should see 0 item

When I fill in the following:
  | qty | 4 |
And I click "Crear nueva"
Then I should see 4 item
When I click "Bajar"

