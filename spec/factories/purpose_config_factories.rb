# frozen_string_literal: true

FactoryBot.define do
  # Builds a config hash as though loaded from config/purposes/*.yml
  # Using create automatically registers it in the Settings object
  factory :purpose_config, class: Hash do
    to_create do |instance, evaluator|
      Settings.purpose_uuids[evaluator.name] = evaluator.uuid
      Settings.purposes[evaluator.uuid] = instance
    end

    initialize_with { attributes }

    transient { uuid { 'example-purpose-uuid' } }

    name { 'Plate Purpose' }
    creator_class { 'LabwareCreators::StampedPlate' }
    presenter_class { 'Presenters::StandardPresenter' }
    state_changer_class { 'StateChangers::DefaultStateChanger' }
    default_printer_type { :plate_a }
    asset_type { 'plate' }
    label_class { 'Labels::PlateLabel' }
    printer_type { '96 Well Plate' }
    pmb_template { 'sqsc_96plate_label_template' }
    file_links { [{ name: 'Download Concentration CSV', id: 'concentrations' }] }

    # Sets up a stock plate configuration
    factory :stock_plate_config do
      transient { uuid { 'stock-plate-purpose-uuid' } }
      name { 'Limber Cherrypicked' }
      presenter_class { 'Presenters::StockPlatePresenter' }
      stock_plate { true }
      cherrypickable_target { true }
      input_plate { true }
    end

    # Sets up config for a plate with custom_metadata_fields parameters
    factory :plate_with_custom_metadata_fields_config do
      name { 'LTHR-384 PCR 2' }
      custom_metadata_fields { ['IDX DFD Syringe lot Number', 'Another'] }
    end

    # Sets up config for a plate with empty custom_metadata_fields parameters
    factory :plate_with_empty_custom_metadata_fields_config do
      name { 'LTHR-384 PCR 2' }
      custom_metadata_fields { [] }
    end

    # Sets up config for a tube with transfer parameters
    factory :tube_with_transfer_parameters_config do
      name { 'LTHR-384 Pool XP' }
      presenter_class { 'Presenters::TubePresenter' }
      transfer_parameters { { target_molarity_nm: 4, target_volume_ul: 192, minimum_pick_ul: 2 } }
    end

    # tube with file links
    factory :tube_with_file_links_config do
      name { 'Bioscan Pool Tube' }
      file_links { [{ name: 'Download MBrave UMI file', id: 'bioscan_mbrave', format: 'tsv' }] }
      presenter_class { 'Presenters::FinalTubePresenter' }
    end

    factory :tag_plate_384_purpose_config do
      name { 'Tag Plate - 384' }
      presenter_class { 'Presenters::TagPlate384Presenter' }
      pmb_template { 'sqsc_384plate_label_template' }
      sprint_template { 'plate_384_single.yml.erb' }
      default_printer_type { :plate_384_single }
      printer_type { '384 Well Plate Double' }
      label_class { 'Labels::Plate384SingleLabel' }
    end

    # Sets up a config with a minimal presenter
    factory :minimal_purpose_config do
      presenter_class { 'Presenters::MinimalPlatePresenter' }
    end

    # Sets up a config with a transfer_template configured
    # eg. LB Cap Lib Pool plate
    factory :templated_transfer_config do
      creator_class { 'LabwareCreators::PlateWithTemplate' }
      transfer_template { 'Pool wells based on submission' }
    end

    # Sets up a purpose with a tagged plate creator
    factory :tagged_purpose_config do
      creator_class { 'LabwareCreators::TaggedPlate' }
      presenter_class { 'Presenters::PcrPresenter' }
      name { 'Tag Purpose' }
      tag_layout_templates { ['tag-layout-template'] }
    end

    # Sets up the configuration required for a Concentration Binned plate
    factory :concentration_binning_purpose_config do
      presenter_class { 'Presenters::ConcentrationBinnedPlatePresenter' }
      creator_class { 'LabwareCreators::ConcentrationBinnedPlate' }
      dilutions do
        {
          source_volume: 10,
          diluent_volume: 25,
          bins: [
            { colour: 1, pcr_cycles: 16, max: 25 },
            { colour: 2, pcr_cycles: 12, min: 25, max: 500 },
            { colour: 3, pcr_cycles: 8, min: 500 }
          ]
        }
      end
    end

    # Sets up the configuration required for a Normalized plate
    factory :fixed_normalisation_purpose_config do
      creator_class { 'LabwareCreators::FixedNormalisedPlate' }
      dilutions { { source_volume: 2, diluent_volume: 33 } }
    end

    # Configuration for a normalized and binned plate purpose
    factory :normalised_binning_purpose_config do
      creator_class { 'LabwareCreators::NormalisedBinnedPlate' }
      presenter_class { 'Presenters::NormalisedBinnedPlatePresenter' }

      dilutions do
        {
          target_amount_ng: 50,
          target_volume: 20,
          minimum_source_volume: 0.2,
          bins: [{ colour: 1, pcr_cycles: 16, max: 25 }, { colour: 2, pcr_cycles: 14, min: 25 }]
        }
      end
    end

    # Configuration for a ConcentrationNormalisedPlate
    factory :concentration_normalisation_purpose_config do
      creator_class { 'LabwareCreators::ConcentrationNormalisedPlate' }
      dilutions { { target_amount_ng: 50, target_volume: 20, minimum_source_volume: 0.2 } }
    end

    factory :duplex_seq_customer_csv_file_upload_purpose_config do
      csv_file_upload do
        {
          input_amount_desired_min: 0.0,
          input_amount_desired_max: 50.0,
          sample_volume_min: 0.2,
          sample_volume_max: 50.0,
          diluent_volume_min: 0.0,
          diluent_volume_max: 50.0,
          pcr_cycles_min: 1,
          pcr_cycles_max: 20,
          submit_for_sequencing_valid_values: %w[Y N],
          sub_pool_min: 1,
          sub_pool_max: 96
        }
      end
    end

    # Configuration for an aggregation plate
    factory :aggregation_purpose_config do
      state_changer_class { 'StateChangers::AutomaticPlateStateChanger' }
      creator_class { 'LabwareCreators::TenStamp' }
      work_completion_request_type { 'limber_bespoke_aggregation' }
    end

    # Configuration for a plate merge purpose
    factory :merged_plate_purpose_config do
      merged_plate do
        { source_purposes: ['Source 1 Purpose', 'Source 2 Purpose'], help_text: 'Some specific help text.' }
      end
    end

    # Configuration for a stamp with randomised controls
    factory :stamp_with_randomised_controls_purpose_config do
      asset_type { 'plate' }
      stock_plate { true }
      cherrypickable_target { true }
      input_plate { false }
      creator_class { 'LabwareCreators::StampedPlateAddingRandomisedControls' }
      presenter_class { 'Presenters::StockPlatePresenter' }
      state_changer_class { 'StateChangers::AutomaticPlateStateChanger' }
      work_completion_request_type { 'limber_bespoke_aggregation' }
      controls do
        [
          { control_type: 'pcr positive', name_prefix: 'CONTROL_POS_' },
          { control_type: 'pcr negative', name_prefix: 'CONTROL_NEG_' }
        ]
      end
      control_study_name { 'UAT Study' }
      control_project_name { 'UAT Project' }
      control_location_rules { [{ type: 'not', value: %w[H1 G1] }, { type: 'well_exclusions', value: %w[H12] }] }
    end

    # Configuration for a multi stamp from tubes plate purpose
    factory :multi_stamp_tubes_purpose_config do
      creator_class { 'LabwareCreators::MultiStampTubes' }
      presenter_class { 'Presenters::SubmissionPlatePresenter' }

      submission_options do
        {
          'Cardinal library prep' => {
            'template_name' => 'example',
            'allowed_extra_barcodes' => false,
            'request_options' => {
              'library_type' => 'example_library',
              'fragment_size_required_from' => '200',
              'fragment_size_required_to' => '800'
            }
          }
        }
      end
    end

    # Configuration for too many purpose configs
    factory :multi_stamp_tubes_purpose_configs do
      submission_options do
        {
          'Cardinal library prep' => {
            'template_name' => 'example',
            'request_options' => {}
          },
          'Another Cardinal library prep' => {
            'template_name' => 'example',
            'request_options' => {}
          }
        }
      end
    end

    # Configuration for a plate split to tube racks purpose
    factory :plate_split_to_tube_racks_purpose_config do
      creator_class do
        {
          name: 'LabwareCreators::PlateSplitToTubeRacks',
          args: {
            child_seq_tube_purpose_name: 'Seq Child Purpose',
            child_spare_tube_purpose_name: 'Spare Child Purpose'
          }
        }
      end
      ancestor_stock_tube_purpose_name { 'Ancestor Tube Purpose' }
    end

    # Basic tube purpose configuration
    factory :tube_config do
      asset_type { 'tube' }
      default_printer_type { :tube }
      presenter_class { 'Presenters::SimpleTubePresenter' }
      state_changer_class { 'StateChangers::TubeStateChanger' }

      # Config for the final tube in a pipeline
      factory :passable_tube do
        presenter_class { 'Presenters::FinalTubePresenter' }
      end

      # Sets up the configuration for tubes in which whole plates are pooled
      factory :pooled_tube_from_plates_purpose_config do
        name { 'Pool tube' }
        creator_class { 'LabwareCreators::PooledTubesFromWholePlates' }
      end

      # Sets up the configuration for tubes in which multiple tubes are pooled
      factory :pooled_tube_from_tubes_purpose_config do
        name { 'Pool tube' }
        creator_class { 'LabwareCreators::PooledTubesFromWholeTubes' }
      end
    end
  end

  factory :tube_rack_config, class: Hash do
    to_create do |instance, evaluator|
      Settings.purpose_uuids[evaluator.name] = evaluator.uuid
      Settings.purposes[evaluator.uuid] = instance
    end

    initialize_with { attributes }

    transient { uuid { 'example-purpose-uuid' } }

    name { 'Tube rack' }
    asset_type { 'tube_rack' }
    default_printer_type { :tube_rack }
    presenter_class { 'Presenters::TubeRackPresenter' }
    state_changer_class { 'StateChangers::DefaultStateChanger' }
    submission { {} }
    label_class { nil }
    printer_type { '96 Well Plate' }
    pmb_template { 'sqsc_96plate_label_template_code39' }
    size { 96 }
  end
end
