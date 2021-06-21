# frozen_string_literal: true

module Robots::Bed
  # Pooling beds can have multiple parents, and have additional methods to support this
  class Pooling < Robots::Bed::Base
    attr_accessor :parents

    def each_parent
      range.each do |i|
        labware_barcode = parent_labwares[i]&.barcode || SBCF::EmptyBarcode.new
        yield(parents[i], labware_barcode)
      end
    end

    def load(barcodes)
      # Ensure we always deal with an array, and any accidental duplicate scans are squashed out
      @barcodes = Array(barcodes).map(&:strip).uniq.reject(&:blank?)

      @labwares = if @barcodes.present?
                    Sequencescape::Api::V2::Plate.find_all({ barcode: @barcodes }, includes: labware_includes)
                  else
                    []
                  end
    end

    private

    def parent_labwares
      return [] if labware.nil?

      @parent_labwares ||= if labware.plate?
                             parent_labwares_of_plate
                           else
                             # currently not used for tubes
                             []
                           end
    end

    def parent_labwares_of_plate
      labware.wells.sort_by(&well_order).each_with_object([]) do |well, plates|
        next if well.upstream_plates.empty? || plates.include?(well.upstream_plates.first)

        plates << well.upstream_plates.first
      end
    end

    def range
      round = states.index(labware.state)
      size = parents.count / states.count
      (size * round...size * (round + 1))
    end
  end
end
