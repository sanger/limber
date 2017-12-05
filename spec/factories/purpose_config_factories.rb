
# frozen_string_literal: true

FactoryGirl.define do
  factory :purpose_config, class: Hash do
    transient do
      name 'Plate Purpose'
      creator_class 'LabwareCreators::Base'
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

    after(:build) do |hash, evaluator|
      hash.merge!(
        name: evaluator.name,
        creator_class: evaluator.creator_class,
        presenter_class: evaluator.presenter_class,
        state_changer_class: evaluator.state_changer_class,
        default_printer_type: evaluator.default_printer_type,
        asset_type: evaluator.asset_type,
        stock_plate: evaluator.stock_plate,
        cherrypickable_target: evaluator.cherrypickable_target,
        input_plate: evaluator.input_plate,
        parents: evaluator.parents,
        tag_layout_templates: evaluator.tag_layout_templates,
        expected_request_types: evaluator.expected_request_types,
        suggest_library_pass_for: evaluator.suggest_library_pass_for
      )
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
