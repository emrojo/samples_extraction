@javascript
Feature: Tracking of status of laboratory assets by an operator
In order to keep track of the actual status of the laboratory assets
An operator
Should be able to know past, present and future of any asset while working with it

Background:

Given I have the following users:
| User    | Role             |
| Alice   | administrator    |
| Bob     | operator         |
| Charles | operator         |

Given I have the following printers:
| Name      | Printer Type | Default |
| printer1  | Tube         | true    |
| printer2  | Plate        | true    |


Given I have to process these tubes that are on my table:
|  Barcode | Facts                   |
|  1       | is:NotStarted, a:Tube   |
|  2       | is:NotStarted, a:Tube   |

Given we use these activity types:
| Name          |
| Tubes to rack |
| Reracking     |

Given we use these step types:
| Name                   | Activity types |
| Start tube process     | Tubes to rack  |
| Create a TubeRack      | Tubes to rack  |
| Put tube in a TubeRack | Tubes to rack  |
| Discard started tube   | Tubes to rack  |

Given the step type "Start tube process" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :NotStarted.
  ?p :maxCardinality """0""".
} => {
  :step :removeFacts {?p :is :NotStarted.}.
  :step :addFacts {?p :is :Started.}.
}.
"""

Given the step type "Discard started tube" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :Started.
  ?p :maxCardinality """0""".
} => {
  :step :removeFacts {?p :is :Started.}.
  :step :addFacts {?p :is :Discarded.}.
}.
"""


Given the step type "Create a TubeRack" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :Started .
  ?q :maxCardinality """1""".
  ?p :maxCardinality """0""".
} => {
  :step :createAsset { ?q :a :TubeRack .}.
} .
"""

Given the step type "Put tube in a TubeRack" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :Started .
  ?q :a :TubeRack .
  ?q :maxCardinality """0""".
  ?p :maxCardinality """0""".
} => {
  :step :addFacts { ?q :contains ?p .}.
  :step :addFacts { ?p :inRack ?q . }.
  :step :unselectAsset ?p .
} .
"""


Given I have the following kits in house
| Barcode | Kit type                           | Activity type |
| 1       | QIAamp Investigator BioRobot       | Tubes to rack |
| 2       | QIAamp Investigator BioRobot       | Tubes to rack |
| 3       | QIAamp Investigator BioRobot       |               |
| 4       | QIAamp 96 DNA QIAcube HT           |               |

Given the laboratory has the following instruments:
| Barcode | Name          | Activity types           |
| 1       | My instrument | Tubes to rack, Reracking |


When I am a user with name "Charles" and role "Operator"
And I use the browser to enter in the application
Then I should see the Instruments page

Then I create an activity with instrument "My Instrument" and kit "1"
Then I should have created an empty activity for "Tubes to rack"

When I scan these barcodes into the selection basket:
|Barcode |
| 1      |
| 2      |

Then I should see these barcodes in the selection basket:
| Barcode |
| 1       |
| 2       |

And I should see these steps available:
| Step                    |
| Start tube process      |


Scenario: Process a group of barcodes from the selection basket

When I log out
And I am not logged in
And I perform the step "Start tube process"
Then I should not have performed the step "Start tube process"

Scenario: Process a group of barcodes from the selection basket

When I perform the step "Start tube process"
Then I should have performed the step "Start tube process"
And I should see these barcodes in the selection basket:
| Barcode |
| 1       |
| 2       |

And I should see these steps available:
| Step                    |
| Create a TubeRack       |
| Discard started tube    |

When I perform the step "Create a TubeRack"
Then I should have created an asset with the following facts:
| Predicate   |  Object       |
| a           |  TubeRack     |

And I should see these steps available:
| Step                    |
| Put tube in a TubeRack  |

When I finish the activity
Then the activity should be finished
