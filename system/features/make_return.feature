@return
Feature: As a salesman I should be able to return items buyed by a client

Background:
  Given I am logged-in into sales with location STORE_1

Scenario: Return some items

Given I go to returns
When It ask for a order code
And I give it a valid code
And The order is a sale
And The order is finished
And The order has items
Then It should ask for the items to be returned
And I should be able to finish the order and download the pdf

# prevent double devolution
Given I go to returns
When It ask for a order code
And I give it an used code, then I should see an error


Scenario: Fail to return some items

Given I go to returns
When It ask for a order code
And I give it an invalid code, then I should see an error


Given I go to returns
When It ask for a order code
And I give it a valid code, but ist's not a sale, then I should see an error



# # not older than x days?
