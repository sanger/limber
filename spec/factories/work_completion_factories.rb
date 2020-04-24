# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # Result of a API V1 work completion
  factory :work_completion, class: Sequencescape::WorkCompletion, traits: [:api_object] do
    json_root { 'work_completion' }

    with_belongs_to_associations 'user', 'target'
    with_has_many_associations 'submissions'
  end
end
