@transport
Feature: New wh_to_pos

Scenario: Create new wh_to_pos order
Given I am logged-in into backend with location WAREHOUSE_1

When I go to departure_wh_to_pos
And I click "Crear nueva"
Then I should see "Escanee los items a agregar a la orden"

Then I fill with some items from w1
When I click "Cerrar la orden y transportar a Local 1"
Then I should see "Transporte de mercaderia entre deposito y punto de venta "


