@transport
Feature: New pos_to_wh

Scenario: Create new pos_to_wh order
Given I am logged-in into sales with location STORE_1

When I go to departure_pos_to_wh
And I click "Crear nueva"
Then I should see "Escanee los items a agregar a la orden"

Then I fill with some items from s1
When I click "Cerrar la orden y transportar a Deposito 2"
Then I should see "Transporte de mercaderia desde local hacia deposito"

