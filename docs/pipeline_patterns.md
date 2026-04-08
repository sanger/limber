<!--
# @markup markdown
# @title Pipeline Patterns
-->

# Description
This file attempts to describe some common pipeline patterns and how you would define those in your configuration files.

## Splitting and Re-Merging
This pattern of branching is for when aliquots are split out and later re-merged.

For example, in the former Heron pipeline the library prep pipeline split into two paths for PCR 1 and 2 processes, then re-merged at the Lib PCR pool plate.
In this scenario the filters are the same for both paths, and we use the {MergedPlate} labware creator to merge the split aliquots back together again (the aliquots from the split paths are mergeable as they share the same sample ids, request ids and library types).

This is the pipeline configuration for the split (at the LTHR-384 RT-Q plate) and re-merge (to create the LTHR-384 Lib PCR pool plate):
```yaml
Heron-384 Tailed A V2:
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

Note there are two pipeline definitions, sharing the same pipeline_group and filters, and the split and merge labware purposes.
Note the initial relationship steps to get to the branch LTHR-384 RT-Q plate are only defined once. As are the steps after the re-merge at the LTHR-384 Lib PCR pool plate.

This is purpose configuration for the merge plate:
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

Note the purpose configuration defines the use of the {MergedPlate} creator and limits it's source purposes to the two plates we intend to merge, the Lib PCR 1 and 2 plates.

The end results are single aliquot libraries.

## Branching into Multiple Library Preps
This pattern for branching is for when the pipeline splits out into multiple library preparation processes. Each library prep process is distinct with it's own submission.

For example, in the chromium pipelines we create a Cherrypick plate and then do partial submissions (subsets of wells) for different library preps.

We have the initial aggregation pipeline that creates the Cherrypick plates from the Stock plates.

```yaml
Bespoke Aggregation:
  filters:
    request_type_key: limber_bespoke_aggregation
  relationships:
    LBC Stock: LBC Aggregate
    LBC Aggregate: LBC Cherrypick
```

Then the Cherrypick plate is the start of multiple forms of library prep. The SSR submits samples on the Cherrypick plates for as many of these library preps as required.

We then have multiple library prep pipeline configs, for 5 prime, BCR and TCR:

```yaml
Bespoke Chromium 5p:
  pipeline_group: Bespoke Chromium 5p
  filters:
    request_type_key: limber_chromium_bespoke
    library_type:
      - Chromium single cell 5 prime
      - Chromium single cell 5 prime HT v2
  library_pass: LBC 5p GEX PCR 2XP
  relationships:
    LBC Cherrypick: LBC 5p GEX Dil
    LBC 5p GEX Dil: LBC 5p GEX Frag 2XP
    LBC 5p GEX Frag 2XP: LBC 5p GEX LigXP
    LBC 5p GEX LigXP: LBC 5p GEX PCR 2XP
```

```yaml
Bespoke Chromium BCR:
  pipeline_group: Bespoke Chromium BCR
  filters:
    request_type_key: limber_chromium_bespoke
    library_type:
      - Chromium single cell BCR
      - Chromium single cell BCR HT
  library_pass: LBC BCR Post PCR
  relationships:
    LBC Cherrypick: LBC BCR Dil 1
    LBC BCR Dil 1: LBC BCR Enrich1 2XSPRI
    LBC BCR Enrich1 2XSPRI: LBC BCR Enrich2 2XSPRI
    LBC BCR Enrich2 2XSPRI: LBC BCR Dil 2
    LBC BCR Dil 2: LBC BCR Post Lig 1XSPRI
    LBC BCR Post Lig 1XSPRI: LBC BCR Post PCR
```

```yaml
Bespoke Chromium TCR:
  pipeline_group: Bespoke Chromium TCR
  filters:
    request_type_key: limber_chromium_bespoke
    library_type:
      - Chromium single cell TCR
      - Chromium single cell TCR HT
  library_pass: LBC TCR Post PCR
  relationships:
    LBC Cherrypick: LBC TCR Dil 1
    LBC TCR Dil 1: LBC TCR Enrich1 2XSPRI
    LBC TCR Enrich1 2XSPRI: LBC TCR Enrich2 2XSPRI
    LBC TCR Enrich2 2XSPRI: LBC TCR Dil 2
    LBC TCR Dil 2: LBC TCR Post Lig 1XSPRI
    LBC TCR Post Lig 1XSPRI: LBC TCR Post PCR
```

Note how each library prep pipeline starts with the LBC Cherrypick plate.
Note how each pipeline has different filters. This means that the green suggested action child create buttons that the user sees depends on the type(s) of submissions the SSR makes.

The end result here is flexible numbers of library preps can be performed on the same plate of prepared samples.
There is enough volume of prepared sample DNA in the Cherrypick plate that several library preps can be done on the same well. This allows for sequencing analysis to make comparisons between the result data from those different library preps.

## Automated Submissions
Technically semi-automatic, this allow the lab staff to press a button in the labware view to generate a submission instead of needing to involve the SSR.

This is useful in high volume pipelines where the submission options don't change.

A prime example of this is in the former Heron (Covid) pipeline. In this pipeline the lab staff were working all hours including at weekends, so SSR support to manually create submissions was not always available. Plus the submissions were identical, which lends itself to an automated solution.

In the purpose configuration for the plate, use the SubmissionPlatePresenter and set the submission_options parameter. For example in Heron we display a choice of 2 green submission option buttons for the user when they view the Cherrypick plate in Limber. These submissions start the library prep pipelines; one pipeline is for a 96-well plate version, the other for 384-well plates, each with different library types:

```yaml
LTHR Cherrypick:
  :asset_type: plate
  :stock_plate: true
  :cherrypickable_target: true
  :input_plate: true
  :creator_class: LabwareCreators::Uncreatable
  :presenter_class: Presenters::SubmissionPlatePresenter
  :submission_options:
    LTHR 96 - NovaSeq:
      template_name: 'Limber - Heron LTHR V2 - Automated'
      request_options:
        library_type: 'Sanger_tailed_artic_v1_96'
        read_length: 150
        fragment_size_required_from: '50'
        fragment_size_required_to: '800'
        primer_panel_name: nCoV-2019/V4.1alt
      allowed_extra_barcodes: false
    LTHR 384 - NovaSeq:
      template_name: 'Limber - Heron LTHR V2 - Automated'
      request_options:
        library_type: 'Sanger_tailed_artic_v1_384'
        read_length: 150
        fragment_size_required_from: '50'
        fragment_size_required_to: '800'
        primer_panel_name: nCoV-2019/V4.1alt
      allowed_extra_barcodes: true
      num_extra_barcodes: 3
```

Note that there are two different pipeline configurations with different filters leading off from this plate (see the `Branching into Multiple Library preps` section above to see how that configuration works).
Note the request options section. This pattern is only possible if you can use the same submission settings every time, it is not flexible. It is meant to be used to save SSRs a time-consuming, repetitive task.

## Custom Pooling
This pattern is used when you cannot predict the pool makeup in advance (when you can commonly use a submission that includes `limber_multiplexing`). For example when the user wants to manually determine the pooling based on QC data.

In this pattern your purpose configuration includes the labware creator {LabwareCreators::CustomPooledTubes}. This labware creator displays a screen that expects a file upload describing which wells from the parent plate will be transferred (pooled) into the child tube (or tubes).
It allows the user to flexibly create pool tubes.
An SSR can then submit the pool tube for sequencing. Or the user can select 'request additional sequencing' on the tube in Sequencescape.

For example, the custom pool tube from the Duplex Seq pipeline:

```yaml
LDS Custom Pool:
  :asset_type: tube
  :target: StockMultiplexedLibraryTube
  :type: IlluminaHtp::InitialStockTubePurpose
  :creator_class: LabwareCreators::CustomPooledTubes
  :presenter_class: Presenters::SimpleTubePresenter
  :default_printer_type: :tube
```

## Tagging
Tagging is the process by which DNA samples are uniquely barcoded (or tagged) with known oligo sequences so that after they are pooled and sequenced the sequencing data can be deconvoluted during analysis.
Tag plates are usually prepared in advance before being used in a pipeline.
At the step in the pipeline where the DNA samples are to be tagged, the user scans one of these pre-prepared tag plates and (if valid) the DNA samples are transfered into that tag plate (ie. the labware creator in this case is not creating a new plate, it is re-purposing an existing tag plate).
The tag plate becomes the child plate. Part of this process involves connecting the tag plate as the valid child plate of the parent, and another part is changing the purpose of the plate to the one it needs to be from the pipeline configuration.

There are two forms of tagging labware creator, standard and custom.

### Standard tagging
Standard tagging does a straight stamp (A1 to A1, B1 to B1 etc). It uses the {LabwareCreators::TaggedPlate}, and you set the valid list of tag_layout_templates the tag plate is allowed to be made from:

```yaml
LDS Lib PCR:
  :asset_type: plate
  :presenter_class: Presenters::PcrPresenter
  :creator_class: LabwareCreators::TaggedPlate
  :tag_layout_templates:
    - TS_pWGSA_UDI96
    - TS_pWGSA_UDI96v2
    - TS_pWGSB_UDI96
    - TS_pWGSC_UDI96
    - TS_pWGSC_UDI_tag60_61_swap
    - TS_pWGSD_UDI96
    - TS_RNAhWGS_UDI_96
```

### Custom tagging
Custom tagging uses the {LabwareCreators::CustomTaggedPlate} labware creator. This has a more flexible Vue JS screen that allows you to modify how the tags are to be laid out.

You can apply offset, walking by and direction algorithms. You can also set for either 1 or 4 tags per well.

```yaml
LBC TCR Post Lig 1XSPRI:
  :asset_type: plate
  :presenter_class: Presenters::PcrPresenter
  :creator_class: LabwareCreators::CustomTaggedPlate
  :tags_per_well: 1
```

For custom tagging you do not specify a list of specific tag layout templates that are allowed, it is flexible (so they can try experimental tag plates).
Optionally though, you can set a filter for the tag groups you will see to limit the lists:
```yaml
:tag_group_adapter_type_name_filter: 'Chromium'
```

This version was developed where there were partial sample plates and the users wished to be able to re-use the same tag plate and offset the start point. e.g. one sample plate uses the first three columns of tags from a tag plate, then the second uses the 4th-6th columns, and so on.

It has also been used by the Bespoke and R&D teams to test tags, where they needed that flexibility to test new processes.
