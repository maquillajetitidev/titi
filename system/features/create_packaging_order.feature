@packaging
Feature: New packaging

Scenario: Create new packaging order
Given I am logged-in into backend with location WAREHOUSE_2

When I go to packaging_list
And I click "Crear nueva"
Then I should see "Seleccionar el producto"
When I fill with a printed label
When I fill with a printed label
When I fill with a printed label
When I fill with a printed label

When I click "Terminar"
Then I should see "La orden esta lista para ser verificada" within ".flash"

When I select the last item and click on the last link
Then I should see "Verificacion de orden de envasado"
And I should see 4 item

When I remove one item I should see one less

When I click "Terminar verificacion"
Then I should see "Todavia quedan items pendientes"
And I should see 3 item

When I verify all items
And I click "Terminar verificacion"
Then I should see "Ordenes de envasado a imputar"


# When I go to allocation_list
When I select the last item and click on the last link
Then I should see the correct title for the allocation of a packaging order
Then If there are missing materials, I should add them
Then The allocation must take place

