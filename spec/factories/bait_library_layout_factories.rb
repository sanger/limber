# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :bait_library_layout, class: Sequencescape::BaitLibraryLayout, traits: [:api_object] do
    json_root 'bait_library_layout'

    with_belongs_to_associations 'plate'

    transient do
      pools [
        { size: 2, bait: 'Human all exon 50MB' },
        { size: 2, bait: 'Mouse all exon' }
      ]
    end

    layout do
      wells = WellHelpers.column_order.dup
      pools.each_with_object({}) do |pool, hash|
        wells.shift(pool[:size]).each { |well| hash[well] = pool[:bait] }
        hash
      end
    end
  end
end
