# frozen_string_literal: true

module Robots::Bed
  # Pooling beds can have multiple parents, and have additional methods to support this
  class Pooling < Robots::Bed::Base
    attr_accessor :parents

    def each_parent
      range.each do |i|
        labware_barcode = parent_labware[i]&.barcode || SBCF::EmptyBarcode.new
        yield(parents[i], labware_barcode)
      end
    end

    def find_all_labware
      Sequencescape::Api::V2::Plate.find_all({ barcode: @barcodes }, includes: [:purpose, { wells: :upstream_plates }])
    end

    def parent_labware
      return [] if labware.nil?

      @parent_labware ||= labware.plate? ? parent_labware_of_plate : []
    end

    private

    def parent_labware_of_plate
      labware
        .wells
        .sort_by(&well_order)
        .each_with_object([]) do |well, plates|
          next if well.upstream_plates.empty? || plates.include?(well.upstream_plates.first)

          plates << well.upstream_plates.first
        end
    end

    def range
      round = states.index(labware.state)
      size = parents.count / states.count
      ((size * round)...(size * (round + 1)))
    end
  end
end
