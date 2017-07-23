@javascript @printing
Feature: Printing barcodes
An operator
Should be able to print barcodes in a background task

Background:
Given I have the following users:
| User    | Role             |
| Alice   | administrator    |
| Bob     | operator         |

Given I have the following printers:
| Name      | Printer Type | Default |
| printer1  | Tube         | true    |
| printer2  | Plate        | true    |

Given I have the following label templates:
| Name          | Type  | External Id |
| Tubetemplate  | Tube  | 1           |
| PlateTemplate | Plate | 2           |

Given I have to process these tubes that are on my table:
|  Barcode        | Facts                   |
|  00000001       | is:NotStarted, a:Tube   |
|  00000002       | is:NotStarted, a:Tube   |
|  00000003       | is:NotStarted, a:Plate  |
|  00000004       | is:NotStarted, a:Plate  |

Given we use these activity types:
| Name          |
| Printing barcodes |

Given we use these step types:
| Name                       | Activity types |
| Create a tube              | Printing barcodes  |
| Create a tube rack in SS   | Printing barcodes  |
| Create a plate in SS       | Printing barcodes  |

Given the step type "Create a tube" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :NotStarted.
  ?p :maxCardinality """0""".
} => {
  :step :removeFacts {?p :is :NotStarted.}.
  :step :createAsset {?p :a :Tube.}.
}.
"""
Given the step type "Create a tube rack in SS" has this configuration in N3:
"""
{
  ?p :a :Plate .
  ?p :is :NotStarted.
  ?p :maxCardinality """0""".
} => {
  :step :removeFacts {?p :is :NotStarted.}.
  :step :addFacts {?p :pushTo :Sequencescape.}.
}.
"""

Given I have the following kits in house
| Barcode | Kit type                           | Activity type |
| 1       | Printing tube                      | Printing barcodes |

Given the laboratory has the following instruments:
| Barcode | Name          | Activity types           |
| 1       | My instrument | Printing barcodes            |

Given I am a user with name "Bob" and role "Operator"

Scenario: Printing a barcode
When I use the browser to enter in the application
And I go to the Instruments page
Then I should see the Instruments page

When I create an activity with instrument "My Instrument" and kit "1"

When I scan these barcodes into the selection basket:
| Barcode       |
| 00000001      |
| 00000002      |

Then I should see these barcodes in the selection basket:
| Barcode        |
| 00000001       |
| 00000002       |

Then I should see these steps available: 
| Step          |
| Create a tube |

When I want to print "2" new barcodes starting from "33" with template "TubeTemplate" at printer "printer1"

And I perform the step "Create a tube"
Then I should have performed the step "Create a tube"
And I should have printed what I expected

@sequencescape
Scenario: Printing a Sequencescape barcode
When I use the browser to enter in the application
And I go to the Instruments page
Then I should see the Instruments page

When I create an activity with instrument "My Instrument" and kit "1"

When I scan these barcodes into the selection basket:
| Barcode        |
| 00000003       |

Then I should see these barcodes in the selection basket:
| Barcode        |
| 00000003       |

And I should see these steps available:
| Step                      |
| Create a tube rack in SS  |

When I want to export a plate to Sequencescape
And I want to print "1" new barcodes starting from "33" with template "PlateTemplate" at printer "printer2"

Then I perform the step "Create a tube rack in SS"

Then I should have performed the step "Create a tube rack in SS"

And I should have printed what I expected
