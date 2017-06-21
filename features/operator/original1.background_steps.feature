@javascript
Feature: Background steps
In order to populate assets with the new knowledge obtained from previous steps
A background step
Should be able to complete the information of the assets of my group with new information
Obtained by applying inference

Background:

Given I have the following users:
| User    | Role             |
| Alice   | administrator    |

Given I have the following printers:
| Name      | Printer Type | Default |
| printer1  | Tube         | true    |
| printer2  | Plate        | true    |


Given I have to process these tubes that are on my table:
|  Barcode | Facts                                   |
|  1       | is:NotStarted, a:Tube, aliquotType:NA   |
|  2       | is:NotStarted, a:Tube, aliquotType: NA  |

Given we use these activity types:
| Name                 |
| Tube transfer        |

Given we use these step types:
| Name                                   | Activity types |
| Create new tube RNA                    | Tube transfer  |
| Create new tube with any aliquot       | Tube transfer  |

Given the step type "Create new tube RNA" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :NotStarted.
  ?p :maxCardinality """0""".
} => {
  :step :createAsset {
    ?q :a :Tube .
    ?q :aliquotType """RNA""" .
    ?q :transferredFrom ?p .    
  }.
  :step :removeFacts {?p :is :NotStarted.}.
  :step :addFacts {
    ?p :is :Started.
    ?p :transfer ?q .
  }.
}.
"""

Given the step type "Create new tube with any aliquot" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :NotStarted.
  ?p :maxCardinality """0""".
} => {
  :step :createAsset {
    ?q :a :Tube .
  }.
  :step :removeFacts {?p :is :NotStarted.}.
  :step :addFacts {
    ?p :is :Started.
    ?p :transfer ?q .
    ?q :transferredFrom ?p .
  }.
}.
"""

Given I have the following kits in house
| Barcode | Kit type                           | Activity type |
| 1       | Tube transfer                      | Tube transfer |

Given the laboratory has the following instruments:
| Barcode | Name          | Activity types           |
| 1       | My instrument | Tube transfer |


Given I am a user with name "Alice" and role "Administrator"
When I use the browser to enter in the application
Then I should see the Instruments page

Scenario: Create a new tube without specifying aliquotType
When I go to the Instruments page
Then I create an activity with instrument "My Instrument" and kit "1"
Then I should have created an empty activity for "Tube transfer"

When I scan these barcodes into the selection basket:
|Barcode |
| 1      |

Then I should see these barcodes in the selection basket:
| Barcode |
| 1       |

Then I should see these steps available:
| Step                    |
| Create new tube with any aliquot       |

And I perform the step "Create new tube with any aliquot"

Then I should have created an asset with the following facts:
| Predicate   |  Object |
| aliquotType |  NA     |

And I should not have created an asset with the following facts:
| Predicate   |  Object |
| aliquotType |  RNA     |

Scenario: Create a new tube specifying aliquotType
When I go to the Instruments page
Then I create an activity with instrument "My Instrument" and kit "1"
Then I should have created an empty activity for "Tube transfer"

When I scan these barcodes into the selection basket:
|Barcode |
| 1      |

Then I should see these barcodes in the selection basket:
| Barcode |
| 1       |

And I perform the step "Create new tube RNA"
Then I should have created an asset with the following facts:
| Predicate   |  Object |
| aliquotType |  RNA     |

And I should not have created an asset with the following facts:
| Predicate   |  Object |
| aliquotType |  NA     |
