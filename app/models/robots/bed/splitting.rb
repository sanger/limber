# frozen_string_literal: true

module Robots::Bed
  # Splitting robots are specific to plates
  class Splitting < Robots::Bed::Base
    attr_accessor :parents

    def find_all_labware
      Sequencescape::Api::V2::Plate.find_all(
        { barcode: @barcodes },
        includes: [:purpose, { wells: :downstream_plates }]
      )
    end

    def child_labware
      return [] if labware.nil?

      @child_labware ||= child_labware_of_plate
    end

    private

    def child_labware_of_plate
      labware
        .wells
        .sort_by(&well_order)
        .each_with_object([]) do |well, plates|
          next if well.downstream_plates.empty?

          plates << well.downstream_plates.first unless plates.include?(well.downstream_plates.first)
        end
    end
  end
end
