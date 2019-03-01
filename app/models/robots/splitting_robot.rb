# frozen_string_literal: true

module Robots
  # A splitting robot takes one parent plate, and transfers it to multiple children
  # Child plates are numbered based on the order in which they first appear when
  # transfers are sorted in column order.
  class SplittingRobot < Robots::Robot
    attr_writer :relationships

    #
    # Returns a hash of bed barcodes and their valid state
    # Also adds any errors describing invalid bed states
    #
    # @return [Hash<String => Boolean>] Hash of boolean indexed by bed barcode
    def valid_relationships
      @relationships.each_with_object({}) do |relationship, validations|
        parent_bed = relationship.dig('options', 'parent')
        child_beds = relationship.dig('options', 'children')
        expected_children = beds[parent_bed].child_plates
        expected_children.each_with_index do |expected_child, index|
          child_bed = child_beds[index]
          validations[child_bed] = check_plate_identity(child_bed, expected_child)
        end
      end
    end
  end
end
