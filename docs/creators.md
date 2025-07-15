<!--
# @markup markdown
# @title Labware Creators
-->

# Description
Labware creator models are defined in `app/models/labware_creators`.
The base class is {LabwareCreators::Base}

A labware creator is responsible for creating the child labware of a parent labware at a specific step in a pipeline.

Each purpose after the initial (stock or input) labwares defined in the files in `config/purposes` will use a labware creator to create instances of labware. This might be the default stamping labware creator, or one that performs more complex functionality.
(Stamping refers to a straight 1:1 transfer of contents from parent to child, e.g. A1->A1, B1->B1, etc. for plates, or a straight tube to tube transfer)

Purpose defaults for each type of Labware are set in the following class during first deployment, which overrides those defaults if set differently by the purposes files:
{file:lib/purpose_config.rb}

In terms of labware creators, the defaults are:
For Plates: {LabwareCreators::StampedPlate}
For Tubes: {LabwareCreators::TubeFromTube}

NB. For Tube racks there are so few use cases as yet that the creation is handled specifically elsewhere (TODO: ?)

TODO: examples of more complex functionality, parameters from purpose
- re-arrangements
- multistamping many to one
- splits one to many
- merges
- tube arraying to create a plate
- pooling to tubes
