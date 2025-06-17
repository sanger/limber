# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :v2_state_change, class: Sequencescape::Api::V2::StateChange do
    skip_create

    id
    target_state { 'passed' }
  end
end
