# frozen_string_literal: true

require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # Generates an incomplete, but sufficient for testing, V2 BaitLibraryLayout
  factory :bait_library_layout, class: Sequencescape::Api::V2::BaitLibraryLayout do
    skip_create

    transient do
      # Provide an array of pools, describing the number of wells in each
      # and the associated bait library (by name). Will automatically set
      # up the correct number of wells, and the pooling information.
      # Wells are assumed to be filled in column order with no gaps.
      # size: The number of wells in the pool
      # bait: The name of the bait library associated with the pool
      pools { [{ size: 2, bait: 'Human all exon 50MB' }, { size: 2, bait: 'Mouse all exon' }] }
    end

    # Builds the layout attribute expected via the API
    # For example:
    # { 'A1' => 'Human all exon 50MB', 'B1' => 'Human all exon 50MB',
    #   'C1' => 'Mouse all exon', 'D1' => 'Mouse all exon'}
    layout do
      wells = WellHelpers.column_order.dup
      pools.each_with_object({}) { |pool, hash| wells.shift(pool[:size]).each { |well| hash[well] = pool[:bait] } }
    end
  end
end
