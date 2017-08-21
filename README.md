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

## Data model:
```text
Kits <-- KitTypes <-- ActivityTypes ---> Activities   
                          |                |
                          V                V
Actions <------------ StepTypes -------> Steps -----------> Step Execution
                     /    |                |
                    /     V                V
ConditionGroups <--/   AssetGroups        Operations
     |                   |
     V                   V
Conditions             Assets --> Facts
```

## Other features:

- Main process is labware type agnostic, any labware description is following 
the description of the ontology created in app/assets/owls/root-ontology.ttl
- Web resources are accessible in .n3 format to be able to create external
scripts for querying the data (see lib/examples)
- Any rules processing is delegated to the delayed job in a background job that
could use other external tools to perform the processing

## To start:
1. Edit the following information in config/environments/#{RAILS_ENV}.rb 
 - PMB_URI : url for the required instance for print my barcode
 - SS_URI : url for Sequencescape

3. Create the label_templates for PrintMyBarcode 
```bash
rake label_templates:setup
```
4. Start the server
```bash
rails server
```

## Other notes:
This application makes use of an inference engine to plan before hand the operations to perform in between the labware. The default engine provided has a very basic functionality to perform very basic rules. To make use of a more sensible set of rules it is recommended to install 'cwm' in the server host (it can be obtained from https://www.w3.org/2000/10/swap/doc/cwm.html ) and provide the following settings in the config file:

  config.cwm_path - path to the folder that contains the cwm binaries
  config.default_n3_resources_url - url for accessing the application
  config.enable_reasoning - set it to true to make use of cwm
