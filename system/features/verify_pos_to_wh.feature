@transport
Feature: Verify pos_to_wh

Scenario: Verify pos_to_wh order
Given I am logged-in into backend with location WAREHOUSE_2

When I go to warehouse_arrivals
Then I should see "Ingresos"

When I select the last item and click on the last link
Then I should see "Verificando ingreso de mercaderia "
# And I should see 2 item


When I click "Terminar verificacion"
Then I should see "Todavia quedan items pendientes"
# And I should see 2 item


When I verify all items
And I click "Terminar verificacion"
Then I should see "Ingresos"
