# frozen_string_literal: true

module Robots::Bed
  # Pooling and Splitting beds can have multiple parents and multiple children,
  # and have additional methods to support this
  class PoolingAndSplitting < Robots::Bed::Base
    attr_accessor :parents

    def each_parent
      range.each do |i|
        labware_barcode = parent_labware[i]&.barcode || SBCF::EmptyBarcode.new
        yield(parents[i], labware_barcode)
      end
    end

    def find_all_labware
      Sequencescape::Api::V2::Plate.find_all(
        { barcode: @barcodes },
        includes: [:purpose, { wells: :upstream_plates }]
      )
    end

    def parent_plates
      return [] if labware.nil?
      return [] unless labware.plate?

      @parent_plates ||= parent_labwares_of_plate
    end

    def child_labwares
      return [] if labware.nil?

      @child_labwares ||= child_labwares_of_plate
    end

    private

    def parent_labwares_of_plate
      labware.wells.sort_by(&well_order).each_with_object([]) do |well, plates|
        next if well.upstream_plates.empty?

        well.upstream_plates.each do |up_plate|
          plates << up_plate unless plates.include?(up_plate)
        end
      end
    end

    def child_labwares_of_plate
      labware.wells.sort_by(&well_order).each_with_object([]) do |well, plates|
        next if well.downstream_plates.empty?

        well.downstream_plates.each do |plate|
          plates << plate unless plates.include?(plate)
        end
      end
    end
  end
end
