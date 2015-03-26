@make_sale
Feature: Make a sale

Scenario: Make a sale and check every option
Given I am logged-in into sales with location STORE_1

When I go to make_sale
Then I should not be able to checkout
Then I should be able to cancel

When I go to make_sale
And I add an item to current sale
Then I should be able to remove the item
When I add an item to current sale
Then I should be able to checkout
