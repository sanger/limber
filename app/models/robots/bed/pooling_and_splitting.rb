# frozen_string_literal: true

module Robots::Bed
  # Pooling and Splitting beds can have multiple parents and multiple children,
  # and have additional methods to support this
  class PoolingAndSplitting < Robots::Bed::Pooling
    attr_accessor :parents

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

          # we expect multiple downstream child plates, not just one as with the pooling bed
          well.downstream_plates.each do |plate|
            next if plates.include?(plate)

            plates << plate
          end
        end
    end
  end
end
