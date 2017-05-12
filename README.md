# samples_extraction

A semantic web customizable tool for worflows definition and data retrieval for updating the information of samples extraction processes in LIMS persistance servers.

FEATURES:

- Inbox of Started and Not Started samples
- Complete Worflow creation from scratch using a browser
- Workflow selection by kit barcode
- Imports and exports labware by barcode from Sequencescape LIMS
- Data retrieval and manipulation by following one of the previously created workflows
- Historical view of the operations performed during an activity
- Print barcodes using PrintMyBarcode service
- Imports and Exports data in CSV, XML and JSON
- Admin view to manage users, printers and labware
- Searching of labwares

DATA MODEL:

Kits <-- KitTypes <-- ActivityTypes ---> Activities     
                          |                |
                          V                V
Actions <------------ StepTypes -------> Steps
                     /    |                |
                    /     V                V
ConditionGroups <--   AssetGroups        Operations
     |                  |
     V                  V
Conditions           Assets --> Facts


DESCRIPTION:

- Labware agnostic schema-less design with data integrity checks performed by using the ontologies declared
- Workflow definition using RDF/N3
- Background jobs approach, where the main tasks are performed in a delayed job queue during user interaction. 
- New knowledge generated from the inferences performed using the ontologies and the declared workflows applied to the current group of labware

To start:
```bash
rake db:drop db:create db:migrate db:seed label_templates:setup
rails server
```
