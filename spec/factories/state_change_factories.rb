# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # Simple V1 payload comming back from a state change
  factory :state_change, class: Sequencescape::StateChange, traits: [:api_object] do
    json_root { 'state_change' }

    with_belongs_to_associations 'target'

    previous_state { 'pending' }
    reason { 'testing this works' }
  end

  factory :v2_state_change, class: Sequencescape::Api::V2::StateChange do
    skip_create

    id
    target_state { 'passed' }
  end
end
