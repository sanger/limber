
# frozen_string_literal: true

FactoryGirl.define do
  factory :purpose_config, class: Hash do
    transient do
      name 'Plate Purpose'
      creator_class 'LabwareCreators::StampedPlate'
      presenter_class 'Presenters::StandardPresenter'
      state_changer_class 'StateChangers::DefaultStateChanger'
      default_printer_type :plate_a
      asset_type 'plate'
      stock_plate false
      cherrypickable_target false
      input_plate false
      parents []
      tag_layout_templates nil
      expected_request_types nil
      suggest_library_pass_for nil
    end

    # Builds the hash up automatically.
    after(:build) do |hash, evaluator|
      evaluator.attribute_lists.each do |list|
        list.names.each do |attribute|
          hash[attribute] = evaluator.send(attribute)
        end
      end
    end

    factory :templated_transfer_config do
      transient do
        transfer_template 'Pool wells based on submission'
      end
    end

    factory :tagged_purpose_config do
      creator_class 'LabwareCreators::TaggedPlate'
      name 'Tag Purpose'
      tag_layout_templates ['tag-layout-template']
    end

    factory :tube_config do
      transient do
        asset_type 'tube'
        default_printer_type :tube
        presenter_class 'Presenters::SimpleTubePresenter'
      end
    end
  end
end
