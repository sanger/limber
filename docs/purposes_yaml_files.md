<!--
# @markup markdown
# @title Purposes yaml files
-->

# Purposes yaml files

There are a number of `*.yml` files located in `config/purposes/`. These files define the creation and display behaviour of the instances of labware made with these purposes, so they do the correct things for that step in their pipeline.

The purpose configurations do not describe how they are connected together to make a pipeline, that is the job of the `config/pipelines/` files.
Note that all purposes configured here should also have an entry in the relationships section of one of the pipeline yaml files. Without this relationship link, Limber will not be able to determine any suggested actions for labwares created with this purpose.

Limber automatically loads all `.yml` files within this directory into the {Settings} when you run `rake config:generate`. It is likely this will be refactored to use a PurposeConfig object in future, to bring it more in line with the {Pipeline} behaviour.

In addition, Limber will also register purposes in Sequencescape upon running `rake config:generate`. This process is idempotent (ie. will only register each purpose once), although is subject to race conditions if run concurrently.
The `rake config:generate` task is run automatically on deployment, and is run in series
on each host to avoid the race conditions.

Filenames, and the grouping of purposes within files, have no functional relevance, and are intended for organizational reasons. For example, the purposes relating to a specific pipeline are typically grouped together in the same file, to make development and deployment easier.

Loading of yaml files is handled by {ConfigLoader::PurposesLoader} which loads all files and detects potential duplicates.

> [TIP]
> - It is suggested that when you create a new pipeline, you create a `purposes.yml` file to match that pipeline.
> - Be aware that purposes can be shared between different pipelines. This is valid, but means you must be more careful using these purposes in pipeline configurations and have explicit filters.

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

Each file is a `.yml` file located in `config/purposes`, it contains the
configuration for one or more purposes.

The top level structure consists of series of keys, uniquely identifying each
purpose. Keys need to be unique across _all_ purposes, not just those within
the same file. Limber will detect duplicate keys, and will raise an exception
on boot.

The key will be used to set the {Sequencescape::Api::V2::Purpose#name}, this is
displayed extensively throughout Limber and Sequencescape, and also appears on
the plate label. Due to space constraints on labels, it is a good idea if
purpose names are kept short. This key is also used to identify plate purposes
in the pipeline configuration.
See [`docs/pipelines_yaml_files.md`](./pipelines_yaml_files.md)

Recently we have taken to prefixing purpose keys with a short 3 or 4 character pipeline identifier, to more easily see what pipeline a purpose belongs to. This helps to keep the purposes unique, whilst still using common naming for similar steps in different pipelines. The prefix usually also starts with an 'L' to denote a Limber pipeline.
e.g. LPL1 PCR XP and LPL2 PCR XP for similar steps in two pipelines.

The values in turn are used to describe each {Sequencescape::Api::V2::Purpose}.
The valid options are detailed in the following section.

### Purpose

Each purpose configures a name, and set of behaviours. As discussed above, the
key is a unique value, which gets used to set the pipeline's name. The example
below shows a plate purpose called 'LPL Example'.

```yaml
LPL Example:
  :asset_type: plate
  :stock_plate: false
  :cherrypickable_target: false
  :input_plate: false
  :size: 96
  :presenter_class: Presenters::StandardPresenter
  :state_changer_class: StateChangers::PlateStateChanger
  :creator_class: LabwareCreators::TaggedPlate
  :default_printer_type: :plate_a
```

The other keys are detailed below. Note, most of these keys are currently
symbols, not strings.

#### :asset_type

**[required]**
Indicates the type of labware, can be either `plate`, `tube` or `tube_rack`.

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
determine which barcode gets shown on downstream ancestors.

```yaml
:input_plate: false
```

Default: `false`

#### :cherrypickable_target

**(plate only)**
Boolean, indicates that the plate will appear as a
cherrypicking target options in Sequencescape. Usually only true for the first
plate in the pipeline. This option is only used to register a purpose in
sequencescape, and does not affect its behaviour in Limber.

```yaml
:cherrypickable_target: false
```

Default: `false`

#### :size

**(plate and tube rack)**
Integer, passed to Sequencescape, specifies the number of wells
on the plate. Assumes a 3:2 shape. Common values are 96, 384. Or
number of tubes in the tube rack. Common values 48, 96.

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
`IlluminaHtp::StockTubePurpose` or `IlluminaHtp::MxTubePurpose`
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

Description of presenters and their behaviour:
See [`docs/presenters.md`](./presenters.md)

```yaml
:presenter_class: Presenters::StockPlatePresenter
```

Default (plate): `Presenters::StandardPresenter`

Default (tube): `Presenters::SimpleTubePresenter`

Default (tube_rack): `Presenters::TubeRackPresenter`

#### :state_changer_class

String, indicates which {StateChangers state changer} to use for the given
purpose. State changers are used on updating labware state, either via a
{Robots::Robot robot} or via the 'Manual Transition' button and
{LabwareController#update}. In the vast majority of cases this can be left as
the default option.

Valid options are subclasses of {StateChangers}.
See `app/models/state_changers.rb`

```yaml
:state_changer_class: StateChangers::PlateStateChanger
```
There are variants for different types of Labwares (plates, tubes and tube racks).
And there are automatic versions of each, these are used when you want to automatically complete the related submission requests when you change the state.

Hierarchy:
- {StateChangers::BaseStateChanger}
  - {StateChangers::PlateStateChanger}
    - {StateChangers::AutomaticPlateStateChanger} [includes AutomaticBehaviour]
  - {StateChangers::TubeRackStateChanger}
    - {StateChangers::AutomaticTubeRackStateChanger} [includes AutomaticBehaviour]
  - {StateChangers::TubeStateChanger}
    - {StateChangers::AutomaticTubeStateChanger} [includes AutomaticBehaviour]


#### :work_completion_request_type

Optional line used in combination with the state_changer_class which applies a filter that limits the state change to complete (pass) only those requests with the supplied key. It is prudent to include this line to prevent completion of the wrong requests by accident.

The request type key will be the same key used in the pipelines filter, which is in turn the same key used for the submission template for the portion of the pipeline being completed.

```yaml
:work_completion_request_type: limber_targeted_nanoseq_isc_prep
```

This is used instead of the manual 'Charge and Pass' button to automatically close a submission at the end of a pipeline section. e.g. it might be used to  close off the sample preparation part of a pipeline before beginning the library prep section.

#### :creator_class

String, indicates which {LabwareCreators labware creator} to use for the given
purpose. {LabwareCreators} are the home of a significant proportion of Limber's
business logic, and determine the way in which labware with this particular
purpose will be created from its parent.

If you want to have purpose configuration parameters that are used in the labware creator, there are two ways to include these in the purpose config yaml:

As arguments under the labware creator line (note the name is specifically defined then the arguments). The main advantage of this method is they are kept together with the creator_class section of the yaml, so you know what they apply to:
e.g.
```yaml
:creator_class:
    name: LabwareCreators::MyLabwareCreator
    args:
      default_volume: 25
      max_volume: 100
```
These can be retrieved in the labware creator code using dig:
e.g.
```code
def default_volume
  purpose_config.dig(:creator_class, :args, :default_volume)
end
```

Alternatively, you can put the parameters anywhere in the purpose yaml. This is valid but perhaps harder to read as not clear they are used by the labware creator class:
e.g.
```yaml
:creator_class: LabwareCreators::MyLabwareCreator
:default_volume: 25
:max_volume: 100
```

These can be retrieved in the labware creator code using fetch:
e.g.
```code
def default_volume
  purpose_config.fetch(:default_volume)
end
```

The default plate creator {LabwareCreators::StampedPlate} handles the transfer
of all wells from the parent plate to the new child plate. Failed and cancelled
wells are not transferred.

The default tube creator {LabwareCreators::TubeFromTube} handles the transfer
of all material from the parent tube to the new child tube.

Description of labware creators and their behaviours:
See [`docs/creators.md`](./creators.md)

```yaml
:creator_class: LabwareCreators::TaggedPlate
```

Default (plate): `LabwareCreators::StampedPlate`

Default (tube): `LabwareCreators::TubeFromTube`

#### :custom_metadata_fields

List of custom metadata fields for which you want to allow the user to enter values for on this labware. This will appear as entry fields on the right of the GUI on the labware view page.

```yaml
:custom_metadata_fields:
    - My Custom Field 1
    - My Custom Field 2
```

See `app/views/plates/sidebars/_default.html.erb`
and `app/views/tubes/sidebars/_default.html.erb`
where there is a card for 'Adding Custom Metadata'.

This is using VueJS to write the metadata values to the Sequencescape database, see:
`app/frontend/javascript/labware-custom-metadata/components/*`

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

params: Optional query parameters to be passed through the the link to the
exports controller.

states: It can be optionally specified for configuring for which labware states
the download button is available. It can be specified as string, symbol, or
array values to set the includes or hash with includes/excludes keys and
string, symbol, or array values.

```yaml
:file_links:
  - name: 'Download Hamilton Cherrypick to Sample Dilution CSV'
    id: 'hamilton_cherrypick_to_sample_dilution'
    states: passed
  - name: Download Concentration (ng/ul) CSV
    id: concentrations_ngul
    params:
      page: 0
    states:
      includes:
        - passed
        - qc_complete
      excludes: [:pending]
```

@note Not all CSV generation has been migrated under the exports controller. See :csv_template

Default (Plate): [{ name: 'Download Concentration (nM) CSV', id: 'concentrations_nm' }]

Default (Tube): []

See [`docs/exports_files.md`](./exports_files.md) for more information on exports.
See [`docs/exports_yaml_files.md`](./exports_yaml_files.md) for more details on the config yaml file for exports.

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

This attribute defines this plate purpose as an alternative labware that could be referred as a workline identifier while printing the barcode for our current plate barcode. This could be apply to distinguish between different workflows for plates when all of them have in common the same stock plate (RT ticket #683047)

```yaml
:alternative_workline_identifier: LB Lib PCR-XP
```

#### :label_template

String, used to select an alternative {Labels::Base label} template, such as for
printing QC labels. A list of valid label templates can be found in
[`config/label_templates.yml`](../config/label_templates.yml)

A label template is a configuration that combines a {Labels::Base label class},
which describes the specific fields (barcode, date, user, etc...) which will be
displayed on a Plate/Tube label, and a print my barcode template, which
describes how those fields are physically laid out on the label.

If unspecified, falls back on the default label template for the given printer type
specified in the defaults_by_printer_type section.
See [`config/label_templates.yml`](../config/label_templates.yml)

```yaml
:label_template: plate_xp
```

#### :submission

Hash, specifying:

template_name: The name of the submission template to use.

request_options: Valid request options hash to pass in to the submission, the
exact keys required will depend on the submission template.

Used by {WorkCompletion} to automatically build a downstream submission when
the labware is charged and passed. This can be useful to, for example, build
sequencing submissions automatically off the final tube in a pipeline, in cases
where it is not possible to build the sequencing requests upfront; such as when
pooling is dynamic.

```yaml
:submission:
  template_name: 'MiSeq for GBS'
  request_options:
    :read_length: 150
```

#### :merger_plate

Boolean, set to true on plate where multiple smaller plates get merged together.
Assists with extracting correct stock plate information when the plates get
split apart further down the pipeline.

Usually used in concert with a creator like {LabwareCreators::QuadrantStamp}

```yaml
:merger_plate: true
```

#### :warnings

Hash, used to generate warnings to the user when expected conditions aren't met.
Valid keys are `pcr_cycles_not_in` where the value should be an array of
acceptable values.

```yaml
warnings:
  pcr_cycles_not_in:
    - 6
```

### :qc_thresholds

Hash used to configure qc sliders for well failing. Without this configuration,
limber will attempt to pick sensible values based on those seen on the plate.

The hash is keyed with the qc attribute (key in the `qc_results` table) under
scrutiny. Values can contain the following keys

name: A user friendly name for the field (String)
units: The expected units. Where possible limber will attempt to convert units
to match. eg. ml -> ul (String)
default_threshold: The value to which the slider will be se initially.
decimal_places: The number of decimal places to 'step' between. Can be negative
to step up in intervals of 10, 100, 1000 etc. Defaults to 2

```yaml
:qc_thresholds:
  viability:
    units: '%'
    default_threshold: 50
  live_cell_count:
    name: Cell count
    units: 'cells/ml'
    default_threshold: 400000
    decimal_places: 0
```

### Presenter/Creator specific configuration

These options are only used for specific creators or presenters.

#### :dilutions

Used to define binning (grouping) both for sorting samples by concentration,
and for annotating the resulting wells with grouping/concentration information
when shown to the user.

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

Other example {LabwareCreators::FixedNormalisedPlate}

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
:work_completion_request_type: 'limber_bespoke_aggregation'
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

#### :enforce_same_template_within_pool

Boolean, specifies whether tagged plates which will end up being pooled together
should use the same tag layout template as each other.
For instance, they should use different tags if they are different samples
and will therefore need to be 'de-plexed' during data analysis, but should
use the same tags if they originate from the same plate and therefore
contain the same samples.

Used by {LabwareCreators::TaggedPlate}. The default behaviour is as if this setting
is set to false, whether or not it exists.

```yaml
:enforce_same_template_within_pool: true
```

#### :disable_cross_plate_pool_detection

Boolean, specifies whether cross-plate pool detection should be disabled for
this creator. This can be useful in cases where a plate is consolidated earlier
in the pipeline, and the plate contains all samples due to be pooled. This may
be desirable as it allow for re-work following a failed tag application.

This option is safest to enable when:

- The pipeline has an earlier consolidation step
- The pipeline will never pool at a higher level than the current late
- Only one template is available anyway

In other scenarios you may be at risk of introducing tag clashes.

See <https://github.com/sanger/limber/issues/647> for more discussion behind the
introduction of this option, and alternative solutions which were ruled out or
postponed.

Used by {LabwareCreators::TaggedPlate}. The default behaviour is as if this
setting is set to false, whether or not it exists.

```yaml
:disable_cross_plate_pool_detection: true
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

### :submission_options:

Hash of workflows to offer the user. Keys are the text that will appear on the
button, and values are a Hash, specifying:

template_name: The name of the submission template to use.

request_options: Valid request options hash to pass in to the submission, the
exact keys required will depend on the submission template.

This mirrors the same structure used by work completions.

```yaml
:submission_options:
  LTHR 96 - NovaSeq:
    template_name: 'Limber - Heron LTHR - Automated'
    request_options:
      library_type: 'Sanger_tailed_artic_v1_96'
      read_length: 150
      fragment_size_required_from: '50'
      fragment_size_required_to: '800'
      primer_panel_name: nCoV-2019/V4.1alt
  LTHR 384 - NovaSeq:
    template_name: 'Limber - Heron LTHR - Automated'
    request_options:
      library_type: 'Sanger_tailed_artic_v1_384'
      read_length: 150
      fragment_size_required_from: '50'
      fragment_size_required_to: '800'
      primer_panel_name: nCoV-2019/V4.1alt
```
