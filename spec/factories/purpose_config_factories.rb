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

    transient do
      uuid { 'example-purpose-uuid' }
    end

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
      transient do
        uuid { 'stock-plate-purpose-uuid' }
      end
      name { 'Limber Cherrypicked' }
      presenter_class { 'Presenters::StockPlatePresenter' }
      stock_plate { true }
      cherrypickable_target { true }
      input_plate { true }
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
      dilutions do
        {
          source_volume: 2,
          diluent_volume: 33
        }
      end
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
          bins: [
            { colour: 1, pcr_cycles: 16, max: 25 },
            { colour: 2, pcr_cycles: 14, min: 25 }
          ]
        }
      end
    end

    # Configuration for a ConcentrationNormalisedPlate
    factory :concentration_normalisation_purpose_config do
      creator_class { 'LabwareCreators::ConcentrationNormalisedPlate' }
      dilutions do
        {
          target_amount_ng: 50,
          target_volume: 20,
          minimum_source_volume: 0.2
        }
      end
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
        {
          source_purposes: ['Source 1 Purpose', 'Source 2 Purpose'],
          help_text: 'Some specific help text.'
        }
      end
    end

    # Basic tube purpose configuration
    factory :tube_config do
      asset_type { 'tube' }
      default_printer_type { :tube }
      presenter_class { 'Presenters::SimpleTubePresenter' }

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
end
