
# frozen_string_literal: true

FactoryGirl.define do
  factory :purpose_config, class: Hash do
    skip_create
    initialize_with { attributes }

    name 'Plate Purpose'
    creator_class 'LabwareCreators::StampedPlate'
    presenter_class 'Presenters::StandardPresenter'
    state_changer_class 'StateChangers::DefaultStateChanger'
    default_printer_type :plate_a
    asset_type 'plate'

    factory :minimal_purpose_config do
      presenter_class 'Presenters::MinimalPlatePresenter'
    end

    factory :templated_transfer_config do
      transfer_template 'Pool wells based on submission'
    end

    factory :tagged_purpose_config do
      creator_class 'LabwareCreators::TaggedPlate'
      name 'Tag Purpose'
      tag_layout_templates ['tag-layout-template']
    end

    factory :tube_config do
      asset_type 'tube'
      default_printer_type :tube
      presenter_class 'Presenters::SimpleTubePresenter'

      factory :pooled_tube_from_plates_purpose_config do
        name 'Pool tube'
        creator_class 'LabwareCreators::PooledTubesFromWholePlates'
      end

      factory :pooled_tube_from_tubes_purpose_config do
        name 'Pool tube'
        creator_class 'LabwareCreators::PooledTubesFromWholeTubes'
      end
    end
  end
end
