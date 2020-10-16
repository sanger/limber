# Pipelines yaml files

There are a number of `*.yml` files located in `app/config/purposes/` these
configure display and behaviour of labware according to their purpose as they
pass through a pipeline.

Limber automatically loads all `.yml` files within this directory into the
{Settings} when you run `rake config:generate`. It is likely this will be
refactored to use a PurposeConfig object in future, to bring it more in line
with the {Pipeline} behaviour.

In addition, limber will also register purposes in Sequencescape upon running
`rake config:generate`. This process is idempotent (ie. will only register
each purpose once), although is subject to race conditions if run concurrently.
`rake config:generate` is run automatically on deployment, and is run in series
on each host to avoid the race conditions.

Filenames, and the grouping of pipelines within files, have no functional
relevance, and are intended for organizational reasons.

Loading of yaml files is handled by {ConfigLoader::PurposesLoader} which
loads all files and detects potential duplicates.

> **TIP**
> It is suggested that where you create a purposes.yml to match the
> corresponding pipeline. However, purposes can be shared between different
> pipelines.

## An example file

This is an example yaml file configuring purposes for a WGS (whole genome
sequencing) pipeline.

```yaml
---
LB Cherrypick:
  :asset_type: plate
  :stock_plate: true
  :cherrypickable_target: true
  :input_plate: true
  :presenter_class: Presenters::StockPlatePresenter
LB Shear:
  :asset_type: plate
LB Post Shear:
  :asset_type: plate
LB End Prep:
  :asset_type: plate
LB Lib PCR:
  :asset_type: plate
  :presenter_class: Presenters::PcrPresenter
  :creator_class: LabwareCreators::TaggedPlate
  warnings:
    pcr_cycles_not_in:
      - 6
  :tag_layout_templates:
  - TS_pWGSA_UDI96
  - TS_pWGSB_UDI96
  - TS_pWGSC_UDI96
  - TS_pWGSD_UDI96
LB Lib PCR-XP:
  :asset_type: plate
  :default_printer_type: :plate_b
  :label_template: plate_xp
  :file_links:
  - name: Download Concentration (nM) CSV
    id: concentrations_nm
  - name: Download Concentration (ng/ul) CSV
    id: concentrations_ngul
LB Lib Pool:
  :asset_type: tube
  :target: StockMultiplexedLibraryTube
  :type: IlluminaHtp::InitialStockTubePurpose
  :creator_class: LabwareCreators::PooledTubesBySubmission
  :presenter_class: Presenters::SimpleTubePresenter
  :default_printer_type: :tube
```

The rest of the document describes the structure of this file, and what each of the keys do.

## Top level

Each file is a `.yml` file located in `app/config/purposes`, it contains the
configuration for one or more purposes.

The top level structure consists of series of keys, uniquely identifying each
purpose. Keys need to be unique across *all* purposes, not just those within
the same file. Limber will detect duplicate keys, and will raise an exception
on boot.

The key will be used to set the {Sequencescape::Api::V2::Purpose#name}, this is
displayed extensively throughout Limber and Sequencescape, and also appears on
the plate label. Due to space constraints on labels, it is a good idea if
purpose names are kept short. This key is also used to identify plate purposes
in the {file:docs/pipelines_yaml_files.md pipeline configuration}.

The values in turn are used to describe each {Sequencescape::Api::V2::Purpose}.
The valid options are detailed in Purpose below.

### Purpose

Each purpose configures a name, and set of behaviours. As discussed above, the
key is a unique value, which gets used to set the pipeline's name. The example
below shows a plate purpose called 'Example plate'.

```yaml
Example plate:
  :asset_type: plate
  :stock_plate: false
  :cherrypickable_target: false
  :input_plate: false
  :size: 96
  :presenter_class: Presenters::StandardPresenter
  :state_changer_class: StateChangers::DefaultStateChanger
  :creator_class: LabwareCreators::TaggedPlate
  :default_printer_type: :plate_a
```

The other keys are detailed below. Note, most of these keys are currently
symbols, not strings.

#### :asset_type

**[required]**
Indicates the type of labware, can be either `plate` or `tube`.

```yaml
:asset_type: plate
```

#### :stock_plate

**(plate only)**
Boolean, indicates that the plate has the stock_plate flag set
in Sequencescape. Usually only true for the first plate in the pipeline.

```yaml
:stock_plate: false
```

Default: `false`

#### :input_plate

**(plate only)**
Boolean, indicates that the plate has the input_plate flag set
in Sequencescape. Usually only true for the first plate in the pipeline. Also
used to determine if the plate shows in the 'New Input Plates' inbox, and to
determine which barcode gets shown on downstream ancestors

```yaml
:input_plate: false
```

Default: `false`

#### :cherrypickable_target

**(plate only)**
Boolean, indicates that the plate will appear as a
cherrypicking target options in Sequencescape. Usually only true for the first
plate in the pipeline.

```yaml
:cherrypickable_target: false
```

Default: `false`

#### :size

**(plate only)**
Integer, passed to Sequencescape, specifies the number of wells
on the plate. Assumes a 3:2 shape. Common values are 96, 384.

Default: 96

#### :target

**(tube only)** **[required]**
String, passed to Sequencescape. Specifies the class of tube used by the tube
purpose.

Typically, one of `StockMultiplexedLibraryTube` or `MultiplexedLibraryTube` the
former it used for intermediate tubes, the latter for the final tube of a
pipeline.

```yaml
:target: StockMultiplexedLibraryTube
```

#### :type

**(tube only)** **[required]**
String, passed to Sequencescape. Specifies the class used for the tube
purpose itself.

Typically, one of `IlluminaHtp::InitialStockTubePurpose`,
`IlluminaHtp::StockTubePurpose` or `IlluminaHtp::MxTubeNoQcPurpose`
the first it used for the first tube of a pipeline, the second for intermediate
tubes, the latter for the final tube of a pipeline.

```yaml
:type: IlluminaHtp::InitialStockTubePurpose
```

#### :presenter_class

String, indicates which {Presenters::Presenter presenter} should be used to help
render the labware show page. For plates should be a subclass of
{Presenters::PlatePresenter} whereas tubes use a subclass of
{Presenters::TubePresenter}.

Presenters encapsulate the logic for rendering views. Custom presenters can be
used to add additional information to the plate summary, enable buttons at
different stages or ensure tag information gets shown.

If you don't need any special behaviour, the defaults should be just fine.

```yaml
:presenter_class: Presenters::StockPlatePresenter
```

Default (plate): `Presenters::StandardPresenter`

Default (tube): `Presenters::SimpleTubePresenter`

#### :state_changer_class

String, indicates which {StateChangers state changer} to use for the given
purpose. State changers are used on updating labware state, either via a
{Robots::Robot robot} or via the 'Manual Transition' button and
{LabwareController#update}. In the vast majority of cases this can be left as
the default option.

Valid options are subclasses of {StateChangers::DefaultStateChanger}.

```yaml
:state_changer_class: StateChangers::DefaultStateChanger
```

Default: `StateChangers::DefaultStateChanger`

#### :creator_class

String, indicates which {LabwareCreators labware creator} to use for the given
purpose. {LabwareCreators} are the home of a significant proportion of Limber's
business logic, and determine the way in which labware with this particular
purpose will be created from its parent.

The default plate creator {LabwareCreators::StampedPlate} handles the transfer
of all wells from the parent plate to the new child plate. Failed and cancelled
wells are not transferred.

The default tube creator {LabwareCreators::TubeFromTube} handles the transfer
of all material from the parent tube to the new child tube.

```yaml
:creator_class: LabwareCreators::TaggedPlate
```

Default (plate): `LabwareCreators::StampedPlate`

Default (tube): `LabwareCreators::TubeFromTube`

#### :default_printer_type

Symbol, either `:plate_a`, `:plate_b`, or `:tube`. Corresponds to printers
defined in `configuration[:printers]` within `lib/tasks/config.rake`.

Determines which printer will be the default option. Typically this is
determined by the lab in which the work will be conducted. `:plate_b` is located
in the 'post' lab, where plates are handled following PCR.

```yaml
:default_printer_type: :plate_a
```

Default (plate): `:plate_a`

Default (tube): `:tube`

#### :file_links

Array, determines the download links that appear in the suggested actions section.
Each entry consists of a hash with the following keys:

name: The text to show on the download button

id: The template to use for the CSV itself. (See {ExportsController} for the
existing templates)

```yaml
:file_links:
- name: 'Download Hamilton Cherrypick to Sample Dilution CSV'
  id: 'hamilton_cherrypick_to_sample_dilution'
- name: Download Concentration (ng/ul) CSV
  id: concentrations_ngul
```

@note Not all CSV generation has been migrated under the exports controller. See :csv_template

Default (Plate): [{ name: 'Download Concentration (nM) CSV', id: 'concentrations_nm' }]

Default (Tube): []

#### :csv_template

String, either `'show_extended'`, `'show'` or leave undefined.

Toggles which template gets used when someone requests PlatesController#show
with an accept 'text/csv'. If left undefined, or set to nil, no link will be
generated.

```yaml
:csv_template: 'show_extended'
```

@deprecated This is pretty much exclusively used for generating the show_extended
            template in the ISC pipeline. :file_links is more flexible.

Default: nil.

#### :alternative_workline_identifier

This attribute defines this plate purpose
as an alternative labware that could be referred as a workline identifier
while printing the barcode for our current plate barcode. This could be apply
to distinguish between different workflows for plates when all of them have in
common the same stock plate (RT ticket #683047)

```yaml
:alternative_workline_identifier: LB Lib PCR-XP
```

#### :label_template

String, used to select an alternative {Labels::Base label} template, such as for
printing QC labels. A list of valid label templates can be found in
{file:config/label_templates.yml}

If unspecified, falls back on the default label template for the given printer
specified in default_pmb_templates in {file:config/label_templates.yml}.

```yaml
:label_template: plate_xp
```

### :submission

Hash, specifying:

  template_name: The name of the submission template to use.

  request_options: Valid request options hash to pass in to the submission, the
                  exact keys required will depend on the submission template.

Used by {WorkCompletion} to automatically build a downstream submission when
the labware is charged and passed.

```yaml
:submission:
  template_name: 'MiSeq for GBS'
  request_options:
    :read_length: 150
```

#### :merger_plate:

Boolean, set to true on plate where multiple smaller plates get merged together.
Assists with extracting correct stock plate information when the plates get
split apart further down the pipeline.

Usually used in concert with a creator like {LabwareCreators::QuadrantStamp}

```yaml
:merger_plate: true
```

### :warnings

Hash, used to generate warnings to the user when expected conditions aren't met.
Valid keys are `pcr_cycles_not_in` where the value should be an array of
acceptable values.

```yaml
warnings:
  pcr_cycles_not_in:
    - 6
```

## Presenter/Creator specific configuration

These options are only used for specific creators or presenters.

#### :dilutions

Used to define binning both for sorting samples by concentration, and for
annotating the resulting wells.

Please see the associated classes for more details.

Used by:
{Presenters::ConcentrationBinnedPlatePresenter}
{Presenters::NormalisedBinnedPlatePresenter}
{LabwareCreators::ConcentrationBinnedPlate}
{LabwareCreators::NormalisedBinnedPlate}
{LabwareCreators::PartialStampedPlate}
{LabwareCreators::ConcentrationNormalisedPlate}
{LabwareCreators::FixedNormalisedPlate}

```yaml
:dilutions:
  :source_volume: 10
  :diluent_volume: 25
  :bins:
  - colour: 1
    pcr_cycles: 16
    max: 25
  - colour: 2
    pcr_cycles: 12
    min: 25
    max: 500
  - colour: 3
    pcr_cycles: 8
    min: 500
    max: 1500
  - colour: 4
    pcr_cycles: 5
    min: 1500
```

Other example (LabwareCreators::FixedNormalisedPlate)
```yaml
:dilutions:
  :source_volume: 2
  :diluent_volume: 33
```

#### :tags_per_well

Integer, used to determine how many tags pairs will be applied to each well.
@note This is not used to distinguish between single indexed and dual indexed
samples. Instead it means multiple i7 tags are selected per well, resulting in
more than one aliquot, each with a different tag.

Used in:
{LabwareCreators::CustomTaggedPlate}

```yaml
:tags_per_well: 4
```

Default: 1

#### :work_completion_request_type

String, used by {StateChangers::AutomaticPlateStateChanger} to determine which
request type to automatically pass when the plate is passed.

```yaml
:state_changer_class: StateChangers::AutomaticPlateStateChanger
```

#### :tag_layout_templates

Array, specifies a list of tag layout template names which are approved
for the creation of this plate purpose. Used by {LabwareCreators::TaggedPlate}.
If an empty array is provided, the value isn't specified, or is set to nil,
all layout templates are approved.

```yaml
:tag_layout_templates:
- 'TS_pWGSA_UDI96'
- 'TS_pWGSB_UDI96'
- 'TS_pWGSC_UDI96'
- 'TS_pWGSD_UDI96'
- 'TS_RNAhWGS_UDI_96'
```

#### :merged_plate

Hash, specifying:

  source_purposes: Array of purpose names that will be merged together onto a
                   single plate.

  help_text: Text to display to the user on the creation page.

Used by {LabwareCreators::MergedPlate}

```yaml
:merged_plate:
    source_purposes:
    - 'LHR-384 PCR 1'
    - 'LHR-384 PCR 2'
    help_text: 'Here we are merging the two Primer Panel PCR plates, creating a new cDNA plate.'
```

#### :transfer_template

String, to specify the name of the transfer template used during plate creation.
Only used by Creators that use transfer templates, such as
{LabwareCreators::PlateWithTemplate}.

@todo Refactor to make this easier to identify exactly which creators this impacts.

```yaml
:transfer_template: 'Pool wells based on submission'
```

Default specified by default_transfer_template_name for the creator class.
