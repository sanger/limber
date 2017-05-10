# frozen_string_literal: true

require_relative '../support/factory_girl_extensions'

FactoryGirl.define do
  factory :bulk_transfer, class: Sequencescape::BulkTransfer, traits: [:api_object] do
    json_root 'bulk_transfer'
    with_has_many_associations 'transfers'
  end
end
