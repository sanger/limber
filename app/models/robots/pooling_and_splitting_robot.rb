# frozen_string_literal: true

module Robots
  class PoolingAndSplittingRobot < Robot # rubocop:todo Style/Documentation
    attr_writer :relationships

    def verified
      @verified ||= {}
    end

    #
    # Returns a hash of bed barcodes and their valid state
    # Also adds any errors describing invalid bed states
    #
    # @return [Hash<String => Boolean>] Hash of boolean indexed by bed barcode
    def valid_relationships
      raise StandardError, "Relationships for #{name} are empty" if @relationships.empty?

      @relationships.each do |relationship|
        parent_beds = relationship.dig('options', 'parents')
        child_beds = relationship.dig('options', 'children')

        used_parents = []
        verify_child_beds(child_beds, parent_beds, used_parents)

        check_for_unused_parents(parent_beds, used_parents)
      end
      verified
    end

    def bed_class
      Robots::Bed::PoolingAndSplitting
    end

    private

    #
    # Verifies that each of the child beds contains a plate, that plate is
    # valid, and that the parents of the child plate are present
    #
    def verify_child_beds(child_beds, parent_beds, used_parents)
      child_beds.each do |child_bed|
        # The parent beds must all have plates
        if beds[child_bed].empty?
          # handle_unexpected_empty_child_bed(verified, child_bed)
          handle_unexpected_empty_child_bed(child_bed)
        elsif beds[child_bed].valid?
          # verify_occupied_child_bed(verified, child_bed, parent_beds, used_parents)
          verify_occupied_child_bed(child_bed, parent_beds, used_parents)
        else
          child_bed_id = beds[child_bed]
          verified[child_bed_id] = false
        end
      end
    end

    #
    # Handles the error where the child bed is empty
    #
    def handle_unexpected_empty_child_bed(child_bed)
      child_bed_id = beds[child_bed]
      verified[child_bed_id] = false
      error(beds[child_bed], 'No destination plate barcode provided')
    end

    #
    # Verifies an occupied child bed has parents
    #
    def verify_occupied_child_bed(child_bed, parent_beds, used_parents)
      # check whether the child plate has parents
      if beds[child_bed].parent_plates.present?
        verify_parent_beds_for_child(child_bed, parent_beds, used_parents)
      else
        child_bed_id = beds[child_bed]
        verified[child_bed_id] = false
        error(beds[child_bed], 'should have parent plates.')
      end
    end

    #
    # Verifies that the parent plates of an occupied child bed are present
    #
    def verify_parent_beds_for_child(child_bed, parent_beds, used_parents)
      # determine what the expected parents should be for this child plate
      expected_parents = beds[child_bed].parent_plates

      # confirm child bed has its expected parents in the correct beds
      expected_parents.each_with_index do |expected_parent, index|
        verify_parent(parent_beds, used_parents, expected_parent, index)
      end
    end

    #
    # Verifies a parent plate has the correct purpose and state
    #
    def verify_parent(parent_beds, used_parents, expected_parent, index)
      parent_bed = parent_beds[index]
      used_parents << parent_bed
      verified[parent_bed] = if beds[parent_bed].valid?
                               check_labware_identity([expected_parent], parent_bed)
                             else
                               false
                             end
    end

    #
    # Checks that only required parent plates are present
    #
    def check_for_unused_parents(parent_beds, used_parents)
      parent_beds.each do |parent_bed|
        next if beds[parent_bed].empty?

        unless used_parents.include?(parent_bed)
          verified[parent_bed] = false
          error(beds[parent_bed], 'is unrelated to the child plates')
        end
      end
    end
  end
end
