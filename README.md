# samples_extraction

A tool to use and customize workflows for tracking information about the
process for samples extraction and update the relevant information in 
Sequencescape.

## Main Features:

- Inbox of Started and Non started samples
- Worflows creation using the GUI with the browser
- Selection of the workflow to use by providing a kit barcode
- Imports and exports labware by barcode from Sequencescape LIMS
- Historical view of the operations performed during an activity.
- Print barcodes using PrintMyBarcode service
- Admin view to manage users, printers and labware
- Functionality for searching of labwares by metadata criteria

## Main Data model:
```text
Kits <-- KitTypes <-- ActivityTypes ---> Activities     
                          |                |
                          V                V
Actions <------------ StepTypes -------> Steps
                     /    |                |
                    /     V                V
ConditionGroups <--   AssetGroups        Operations
     |                  |
     V                  V
Conditions            Assets --> Facts
```

## Other features:

- Main process is labware type agnostic, any labware description is following 
the description of the ontology created in app/assets/owls/root-ontology.ttl
- Web resources are accessible in .n3 format to be able to create external
scripts for querying the data (see lib/examples)
- Any rules processing is delegated to the delayed job in a background job that
could use other external tools to perform the processing

## To start:

1. Modify config/enviroments/... PMB_URI to link with the required instance for
 print my barcode
2. Modify config/environments SS_URI to link with Sequencescape and start Sequencescape
3. Create the label_templates for PrintMyBarcode 
```bash
rake label_templates:setup
```
4. Start the server
```bash
rails server
```
