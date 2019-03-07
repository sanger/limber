# frozen_string_literal: true

module Robots::Bed
  # Pooling beds can have multiple parents, and have additional methods to support this
  class Pooling < Robots::Bed::Base
    attr_accessor :parents

    def each_parent
      range.each do |i|
        plate_barcode = if parent_plates[i].present?
                          parent_plates[i].barcode
                        else
                          SBCF::EmptyBarcode.new
                        end
        yield(parents[i], plate_barcode)
      end
    end

    private

    def parent_plates
      @parent_plates ||= @parent_plates ||= plate.wells.sort_by(&well_order).each_with_object([]) do |well, plates|
        next if well.upstream_plates.empty? || plates.include?(well.upstream_plates.first)

        plates << well.upstream_plates.first
      end
    end

    def range
      round = states.index(plate.state)
      size = parents.count / states.count
      (size * round...size * (round + 1))
    end
  end
end
