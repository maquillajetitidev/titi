@transport
Feature: New wh_to_wh

Scenario: Create new wh_to_wh order
Given I am logged-in into backend with location WAREHOUSE_2

When I go to departure_wh_to_wh
And I click "Crear nueva"
Then I should see "Escanee los items a agregar a la orden"

Then I fill with some items from w2
Then I fill with some bulks from w2
When I click "Cerrar la orden y transportar a Deposito 1"
Then I should see "Transporte de mercaderia entre depositos"

