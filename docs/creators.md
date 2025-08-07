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

## Defaults
Purpose defaults for each type of Labware are set in the following class during first deployment, which overrides those defaults if set differently by the purposes files:
[`lib/purpose_config.rb`](../lib/purpose_config.rb)

In terms of labware creators, the defaults are:
For Plates: {LabwareCreators::StampedPlate}
For Tubes: {LabwareCreators::TubeFromTube}

NB. For Tube racks there is no default as the tube rack creation is usually deferred to Sequencescape.
For example see {LabwareCreators::PlateSplitToTubeRacks}

## Other types of labware creators
There are many examples of Labware creators with more complex functionality. Some examples of processes these perform when creating their child labwares include:

### tagged plates
Where the child plate is a pre-existing tag plate created in advance of use in a pipeline. The user scans in the tag plate barcode to the labware creator screen and transfers the parent samples into it, re-purposing it for the step in the pipeline.
For examples see {LabwareCreators::TaggedPlate} which does a straight stamp into the tag plate, and the more flexible {LabwareCreators::CustomTaggedPlate} which allows you to set tag offsets and other arrangement parameters.

### binning re-arrangements
Where well contents are binned according to concentration, compressed to top left of a plate, or otherwise moved around.
For examples, see {LabwareCreators::ConcentrationBinnedPlate} which performs binning by concentration into columns, and {LabwareCreators::PcrCyclesBinnedPlateForTNanoSeq} which is similarly binning by concentration to a strip tube 'plate' that is split up by columns for different numbers of PCR cycles.

### multi-stamping many to one
Where more than one parent labware is combined to create a single child labware.
For examples, see {LabwareCreators::QuadrantStamp} which creates a 384-well plate from four 96-well plates, {LabwareCreators::TenStamp} which compresses samples from up to ten 96-well plates into one, and {LabwareCreators::MultiStampTubes} which arrays multiple tubes into a plate.

### splits one to many
Where one labware is split into many child labwares.
For examples, see {LabwareCreators::QuadrantSplitPlate} which splits a 384-well plate out into four 96-well plates, and {LabwareCreators::PlateSplitToTubeRacks} which splits a plate out into multiple tubes in 2 tube racks.

### merges
Where a number of parent labwares are merged together into a single child labware.
For examples, see {LabwareCreators::MergedPlate} which merges the aliquots in corresponding wells from 2 parent plates to create a single child plate, and {LabwareCreators::BlendedTube} which merges 2 pool tubes together and blends aliquots with the same samples and tags.

### pooling to tubes
Where multiple samples from a parent labware are pooled together into a child labware according to specific strategies.
For examples, see {LabwareCreators::PooledTubesBySample} which pools together those wells with the same sample, from multiple plate wells into a child tube for each sample, {LabwareCreators::PooledTubesBySubmission} which is similar but pools together plate wells with samples that have the same submission and places them in child tubes, and {LabwareCreators::PooledWellsBySampleInGroups} which pools together wells with the same samples into wells on a child plate.

> [TIP]
> - When trying to determine whether you need to create a new labware creator or can re-use an existing one it is useful to first try and identify if there is a similar step in an existing pipeline.
> - If necessary you can refactor an existing labware creator to make it more flexible. For example by using optional parameters with different values for the new use case. Or extend an existing labware creator with a new subclass that holds the additional functionality you need.
