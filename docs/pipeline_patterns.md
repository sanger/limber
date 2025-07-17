<!--
# @markup markdown
# @title Pipeline Patterns
-->

# Description
This file attempts to describe some common pipeline patterns and how you would define those in your configuration files.

## Branching and Re-Merging
For example, in the Heron pipeline the library prep pipeline branches into two paths for PCR 1 and 2 processes, then re-merges at the Lib PCR pool plate. In this scenario the filters are the same for both branches, and we use the MergedPlate labware creator to merge the split aliquots back together again (the aliquots are mergeable as they share the same sample ids, request ids and library types).

pipeline configuration for the branching:
```yaml
Heron-384 Tailed A V2: # Heron 384-well pipeline specific to PCR 1 plate
  pipeline_group: Heron-384 V2
  filters: &heron_tailed_filters
    request_type_key: limber_heron_lthr_v2
    library_type:
      - Sanger_tailed_artic_v1_384
  library_pass: LB Lib Pool Norm
  relationships:
    LTHR Cherrypick: LTHR-384 RT-Q
    LTHR-384 RT-Q: LTHR-384 PCR 1
    LTHR-384 PCR 1: LTHR-384 Lib PCR 1
    LTHR-384 Lib PCR 1: LTHR-384 Lib PCR pool
    LTHR-384 Lib PCR pool: LTHR-384 Pool XP
    LTHR-384 Pool XP: LB Lib Pool Norm
Heron-384 Tailed B V2:
  pipeline_group: Heron-384 V2
  filters: *heron_tailed_filters
  library_pass: LB Lib Pool Norm
  relationships:
    LTHR-384 RT-Q: LTHR-384 PCR 2
    LTHR-384 RT: LTHR-384 PCR 2
    LTHR-384 PCR 2: LTHR-384 Lib PCR 2
    LTHR-384 Lib PCR 2: LTHR-384 Lib PCR pool
```

purpose configuration for the merge plate:
```yaml
LTHR-384 Lib PCR pool:
  :asset_type: plate
  :creator_class: LabwareCreators::MergedPlate
  :merged_plate:
    source_purposes:
      - 'LTHR-384 Lib PCR 1'
      - 'LTHR-384 Lib PCR 2'
    help_text: 'Here we are merging the two Lib PCR plates, creating a new library plate.'
```

Note the two pipeline definitions, sharing the same pipeline_group and filters.
Note the initial relationship steps to get to the branch LTHR-384 RT-Q plate are only defined once. As are the steps after the re-merge at the LTHR-384 Lib PCR pool plate.
Note the purpose configuration defines the usage of the MergedPlate creator and limits it's source purposes to the Lib PCR 1 and 2 plates.

The end results are single libraries.

## Branching into Multiple Library Preps

TODO:
Branching to multiple library preps
Merging
Automatic Submissions
Pooling