@transport
Feature: Verify wh_to_pos

Scenario: Verify wh_to_pos order
Given I am logged-in into sales with location STORE_1

When I go to store_arrivals
Then I select the last item and click on the last link
Then I should see "Verificando ingreso de mercaderia "
And I should see 2 item


When I click "Terminar verificacion"
Then I should see "Todavia quedan items pendientes"
And I should see 2 item


When I verify all items
And I click "Terminar verificacion"
Then I should see "Ingresos"
