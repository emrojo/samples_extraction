# samples_extraction

A workflow processor and management tool supported in metadata annotations that allows a user to specifiy the decisions to make during the process of a group of labware. Actions can be specified as metadata changes definition or as external scripts, allowing it to interact with external persistance applications.

## Main Features:

- UI for workflows creation and process
- Background jobs management for the actions of the workflow
- JSON API available for external services to access the metadata
- External applications required: Sequencescape (storage), PrintMyBarcode (printing)
- Searching facilities for labware based on metadata
- Kits, kit types, users, printers

## Requirements

- Sequencescape
- PrintMyBarcode
- Redis
- Mysql

## Installation

## Setup a development environment in local

This installation procedure is prepared for a MacOS environment:

### Redis

1. Install redis as we will need it (for example, using Homebrew):

```
    # brew install redis
```

2. Start redis

```
    # redis-server
```

### Print_my_barcode config

1. Add the barcode printers that you would like to use in the server. In a MacOS environment open Settings/Printers & Scanners and add the barcode printers making sure they are defined with protocol LPD.

2. In the rails console, run the following command to add the printer we require into the database:

```
  > Printer.create(name: PRINTER_NAME)
```

3. In print_my_barcode folder, start the server

```
  # rails s -p10000
```

4. In Samples Extraction project folder, run the following command to create the required label templates into print_my_barcode:

```bash
  # rake label_templates:setup
```

### mysql

1. Start the server

```
  # mysql.server start
```

### Sequencescape

1. Start the delayed jobs:

```
  # rake jobs:work
```

2. Start the Sequencescape server:

```
  # rails s
```

### Samples extraction config

1. Install all the dependencies for the project

```
  # gem install bundler

  # bundle install

  # bundle exec rake db:setup

  # yarn
```

2. From the project folder, run the command

```
  # rake secret
```

3. Copy the resulting string and create a config/secrets.yml file and paste the string as value from secret_key_base attribute:

```
development:
  secret_key_base: <RANDOM_STRING_OBTAINED>
```

4. Run the delayed job for Samples extraction

```
  # rake jobs:work
```

5. Run the server in a different port than the other services

```
  # rails s -p9000
```

## Starting procedure:

First, start all the required service applications and configure their endpoints by defining
the following environment variables:

- SE_SS_URI: Sequencescape API V1 (Defaults: http://localhost:3000/api/1/)
- SE_SS_API_V2_URI: Sequencescape API V2 (Defaults: http://localhost:3000)
- SE_PMB_URI: PrintMyBarcode URI (Defaults: http://localhost:10000/v1)
- SE_REDIS_URI: Redis DB (Defaults: redis://127.0.0.1:6379)

Additionally you may require to configure the database connection and credentials for mysql from database.yml.

Second, start the background jobs processor:

```bash
rake jobs:work
```

Finally, start the main server:

```bash
bundle exec puma
```

## Running Javascript tests

```
  yarn test
```

## Running tests in watch mode

```
  yarn test-watch
```

## Debugging Javascript with Chrome DevTools

- Add a line 'debugger' in the JS code where we want to add a breakpoint

- Then in Chrome type this URL: about://inspect.

- Click the Open dedicated DevTools for Node

- Run the tests in debug mode:

```
  yarn test:debug
```

## Description

### Selection of workflows

Workflows are selected by using one of the instruments from the instruments view at /instruments and scanning for them a kit barcode. The kit barcode is linked with one of the available workflows so it will create a new Activity to start processing labware with that workflow.

### Brief description of the workflow process

When inside an activity, labware from Sequencescape can be imported by scanning the barcode of
the labware in the box of a group of labware. At the beginning only one group is available, but
may change during process. Depending on the selected group of labware the interface will show
different information.

#### Annotations stage

With the information from Sequencescape a new asset will be created in Extraction lims, and annotated with metadata with the relevant information for the activity type. Asset and Metadata information are stored in the tables Assets and Facts. If the scanned labware already existed,
the metadata will be refreshed from Sequencescape to reflect the changes. Before the rules
matching stage, all assets metadata will be refreshed from Sequencescape.

#### Rules matching stage

A rule system that works with this metadata annotation is used afterwards to show the user the available actions that can be performed with the group of labware scanned. The rule system is represented in the tables ActivityTypes (group of all rules available), StepTypes (each individual rule, that represents a possible interaction for the user), ConditionGroups (a group pattern that represents the antecedent of the rule) and Conditions (each individual condition a group should match).

#### User interaction stage

The user can then select one of the options available and run that rule. Every step can have
a different interaction control defined by the step template. By default, the step template
will be a button. When clicking the button the user runs the action for that rule in the
selected group.

#### Rules execution stage

The actions of the rule to ran are queued in a table in the database. A background processor
(delayed_jobs) will load this changes to apply and run the associated action for the rule.
Actions can be a combination of external scripts and metadata changes definitions. All metadata
changes are gathered to be applied in a single commit in the database.

### User interface sections

#### Groups of assets

A tab-based control table will allow to change the selection of the group of assets to work with.
Each panel contains a list of labware.

#### Rules compatible

A set of controls to allow the user to run the available rules

#### Rules running

A table showing the background jobs already running, with a control allowing to stop the job if
needed. Stopping the job will revert all metadata changes.

#### Rules applied

All applied changes from past rules are stored in the Operations table and displayed in this
view.
A set of controls is provided so the user can perform the following actions:

- Cancel applied rules by reverting all metadata changes, which it would allow to revert history
- Re-apply cancelled rules
- Continue with already stopped jobs (this is really a re-run, as the changes
  from a stopped job are always reverted)

#### User feedback

Changes are broadcasted to the user interface by websockets with the support of a Redis database. The interface is updated with the changes in the database. All changes in available groups, assets, metadata and rules to apply are updated in the user interface automatically.

#### Data model:

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

## Linting and formatting

Linting and formatting are provided by rubocop, prettier and Eslint. I strongly
recommend checking out editor integrations. Also, using lefthook will help
ensure that only valid files are committed.

```shell
# Run rubocop
bundle exec rubocop
# Run rubocop with safe autofixes
bundle exec rubocop -a
# Check prettier formatting
yarn prettier --check .
# Fix prettier formatting
yarn prettier --write .
```
