# frozen_string_literal: true

module Robots
  class PlateToTubeRacksRobot < Robots::Robot
    attr_writer :relationships

    def bed_class
      Robots::Bed::PlateToTubeRacksBed
    end

    def bed_labwares=(bed_labwares)
      super
      parents = beds.values.select { |bed| bed.labware && bed.child_labware }
      beds.values.each { |bed| bed.load_labware_from_parents(parents) if bed.labware.blank? }
    end

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
  end
end
