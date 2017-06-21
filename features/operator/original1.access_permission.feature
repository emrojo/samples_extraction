@javascript
Feature: An operator can access the functionality of tracking labware
In order to keep a sorted set of options for each type of user
An operator
Should only be able to use the options needed for tracking labware
And not modify any other configuration.

Background:

Given I have the following users:
| User    | Role             |
| Alice   | administrator    |
| Bob     | operator         |

Given I have the following printers:
| Name      | Printer Type | Default |
| printer1  | Tube         | true    |
| printer2  | Plate        | true    |

Scenario: Access to the system functionalities depending on the role of the user

When I use the browser to enter in the application
Then I should see the Instruments page

When I log in as an unknown user
Then I am not logged in
And I should not be able to access the functionality needed for an operator
And I should not be able to access the functionality needed for an administrator

When I log in as "Bob"
Then I am logged in as "Bob"
And I should be able to access the functionality needed for an operator
And I should not be able to access the functionality needed for an administrator

When I log out
And I log in as "Alice"
Then I am logged in as "Alice"
And I should be able to access the functionality needed for an administrator

And I log out
Then I am not logged in
