<!--
# @markup markdown
# @title Labware Presenters
-->

# Description
Labware presenter models are defined in `app/models/presenters`.

The job of a Presenter is to produce the view for a specific instance of Labware after it has been created by a labware creator. All Presenters extend the same base class and have a similar layout to keep a uniform look and feel.

Typically the left side of the view displays information about the Labware instance, and on the right are the actions that can be performed on it.

At the top left is the Labware purpose, barcode and state. Plus a ticker that attempts to show you what step you are at in the pipeline.

The view on the left for plates usually includes (but not always) a visual representation of the wells within the plate and their state (flexible display based on the size parameter of the labware to handle 96, 384 and other formats of wells). Under that are a number of tabs of summary information.

The view on the left for tubes is similar but simpler, a visual representation of the tube plus summary tabs of information.

The view on the left for tube racks is similar to plates, but displays the tubes and their layout in the rack instead of wells.

On the right side are Labware actions for options like label printing, QC, suggested next pipeline actions, file export options, state operations and other actions (Limber allows you to attempt to create a child labware of any purpose at your own risk).

## Presenter variants
There are many variants of Presenters to meet the specific needs of the step of the pipeline that you are in and the type of labware you are trying to display. They include various shared modules. Some examples of Presenters include:

### Stock Presenters
These typically prevent failing, and use a different state machine that checks for an active Submission to confer 'passed' state.

### PCR Presenters
This typically replace the labware visualisation with a PCR panel that reminds the lab staff what settings to use on the thermal cycler PCR machines.

### Unknown Presenters
These are for labwares with purposes that Limber doesn't recognise. These are typically plates for Sequencescape pipelines that have no configuration in Limber.

## Presenter Modules
These are concerns which infer extra functionality or behaviour on the Presenter. Found in `app/models/concerns/presenters`.

### Creation Behaviour
Included in any Presenter that needs to create child labwares. Used to determine and display suggested action labware creation buttons for this labware. Works out what step in the pipeline you are currently at using purpose and requests, and what is the next purpose to be created.

### Extended CSV
Used specifically to create an extended csv for plates.

### Robot Controlled
Used to determine and display suitable bed verification buttons for this labware.

### State Changeless
Used when you do not want it to be possible to change the state of this labware.

### Statemachine
Used by most labwares to control state transitions.

### Stock Behaviour
Prevents state change and overrides display of input plate (it is the input plate) for this labware.

### Submission Behaviour
Displays submission options for this labware.

### Statemachine variants
Found in `app/models/concerns/presenters/statemachine`
This collection of modules confer additional state machine functionality for use in specific situations.