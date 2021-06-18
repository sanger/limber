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

    private

    def parent_labwares
      return [] if labware.nil?

      @parent_labwares ||= if labware.plate? then
                             get_parent_labwares_of_plate
                           elsif
                             get_parent_labwares_of_tube
                           else
                             []
                           end
    end

    def get_parent_labwares_of_plate
      labware.wells.sort_by(&well_order).each_with_object([]) do |well, plates|
        next if well.upstream_plates.empty? || plates.include?(well.upstream_plates.first)

        plates << well.upstream_plates.first
      end
    end

    def get_parent_labwares_of_tube
      # TODO: tube logic for getting parents
      return []
    end

    def range
      round = states.index(labware.state)
      size = parents.count / states.count
      (size * round...size * (round + 1))
    end
  end
end
