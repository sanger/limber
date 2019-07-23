# frozen_string_literal: true

FactoryBot.define do
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

    factory :passable_plate do
      suggest_library_pass_for { ['Limber Library Creation'] }
    end

    factory :minimal_purpose_config do
      presenter_class { 'Presenters::MinimalPlatePresenter' }
    end

    factory :templated_transfer_config do
      transfer_template { 'Pool wells based on submission' }
    end

    factory :tagged_purpose_config do
      creator_class { 'LabwareCreators::TaggedPlate' }
      presenter_class { 'Presenters::PcrPresenter' }
      name { 'Tag Purpose' }
      tag_layout_templates { ['tag-layout-template'] }
    end

    factory :concentration_binning_purpose_config do
      concentration_binning do
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

    factory :fixed_normalisation_purpose_config do
      fixed_normalisation do
        {
          source_volume_ul: 2,
          diluent_volume_ul: 33
        }
      end
    end

    factory :binned_normalisation_purpose_config do
      binned_normalisation do
        {
          target_amount_ng: 50,
          target_volume_ul: 20,
          minimum_source_volume_ul: 0.2,
          bins: [
            { colour: 1, pcr_cycles: 16, max: 25 },
            { colour: 2, pcr_cycles: 14, min: 25 }
          ]
        }
      end
    end

    factory :tube_config do
      asset_type { 'tube' }
      default_printer_type { :tube }
      presenter_class { 'Presenters::SimpleTubePresenter' }

      factory :passable_tube do
        presenter_class { 'Presenters::FinalTubePresenter' }
        suggest_library_pass_for { ['Limber Library Creation'] }
      end

      factory :pooled_tube_from_plates_purpose_config do
        name { 'Pool tube' }
        creator_class { 'LabwareCreators::PooledTubesFromWholePlates' }
      end

      factory :pooled_tube_from_tubes_purpose_config do
        name { 'Pool tube' }
        creator_class { 'LabwareCreators::PooledTubesFromWholeTubes' }
      end
    end
  end
end
