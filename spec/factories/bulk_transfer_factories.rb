# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # Create an API-V1 BulkTransfer
  # Used in the LabwareCreators::MultiPlatePool
  factory :bulk_transfer, class: Sequencescape::BulkTransfer, traits: [:api_object] do
    json_root { 'bulk_transfer' }
    with_has_many_associations 'transfers'
  end
end
