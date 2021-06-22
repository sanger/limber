# frozen_string_literal: true

module Robots
  # A splitting robot takes one parent labware, and transfers it to multiple children
  # Child labwares are numbered based on the order in which they first appear when
  # transfers are sorted in column order.
  class SplittingRobot < Robots::Robot
    attr_writer :relationships

    def well_order
      :quadrant_index
    end

    #
    # Returns a hash of bed barcodes and their valid state
    # Also adds any errors describing invalid bed states
    #
    # @return [Hash<String => Boolean>] Hash of boolean indexed by bed barcode
    # rubocop:todo Metrics/MethodLength
    def valid_relationships # rubocop:todo Metrics/AbcSize
      raise StandardError, "Relationships for #{name} are empty" if @relationships.empty?

      @relationships.each_with_object({}) do |relationship, validations|
        parent_bed = relationship.dig('options', 'parent')
        child_beds = relationship.dig('options', 'children')

        validations[parent_bed] = beds[parent_bed].child_labware.present?
        error(beds[parent_bed], 'should not be empty.') if beds[parent_bed].empty?
        error(beds[parent_bed], 'should have children.') if beds[parent_bed].child_labware.empty?

        expected_children = beds[parent_bed].child_labware
        expected_children.each_with_index do |expected_child, index|
          child_bed = child_beds[index]
          validations[child_bed] = check_labware_identity([expected_child], child_bed)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def bed_class
      Robots::Bed::Splitting
    end
  end
end
