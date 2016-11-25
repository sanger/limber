require_relative '../support/factory_girl_extensions'

FactoryGirl.define do
  factory :state_change, class: Sequencescape::StateChange, traits: [:api_object] do
    json_root 'state_change'

    with_belongs_to_associations 'target'

    previous_state "pending"
    reason "testing this works"

  end
end