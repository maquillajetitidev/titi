@transport @wip
Feature: Verify wh_to_wh

Scenario: Verify wh_to_wh order
Given I am logged-in into backend with location WAREHOUSE_1

When I go to warehouse_arrivals


And I select the last item and click on the last link
Then I should see "Verificando ingreso de mercaderia "
# And I should see 4 item


When I click "Terminar verificacion"
Then I should see "Todavia quedan items pendientes"
And I should see 4 item


When I verify all items
And I click "Terminar verificacion"
Then I should see "Ingresos"
