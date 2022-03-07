# frozen_string_literal: true

module Robots
  # Core robot class. Used when plates have a simple
  # 1:1 parent child relationship.
  # Todo: Improve class length by using rails error handling
  # rubocop:disable Metrics/ClassLength
  class Robot
    include Form

    attr_reader :beds
    attr_accessor :api, :user_uuid, :layout, :name, :id, :verify_robot, :class, :robot_barcode, :require_robot

    alias verify_robot? verify_robot
    alias require_robot? require_robot

    def well_order
      :coordinate
    end

    def perform_transfer(bed_settings)
      beds.each do |id, bed|
        bed.load(bed_settings[id]) if bed.transitions?
        bed.valid? || raise(Bed::BedError, bed.error_messages)
      end
      beds.values.each(&:transition)
    end

    def formatted_message
      error_messages.join(' ')
    end

    def verify(params)
      assign_attributes(params)
      validation_report
    end

    def validation_report
      verified = valid_labwares.merge(valid_relationships) { |_k, v1, v2| v1 && v2 }
      verified['robot'] = valid_robot
      Report.new(verified, verified.values.all?, formatted_message)
    end

    def beds=(new_beds)
      beds = Hash.new { |store, barcode| store[barcode] = Robots::Bed::Invalid.new(barcode) }
      new_beds.each do |id, bed|
        beds[id] = bed_class.new(bed.merge(robot: self))
      end
      @beds = beds
    end

    def bed_labwares=(bed_labwares)
      bed_labwares.each do |bed_barcode, labware_barcodes|
        beds[bed_barcode.strip].load(labware_barcodes)
      end
    end

    private

    def error(bed, message)
      error_messages << "#{bed.label}: #{message}"
      false
    end

    def bed_error(bed)
      error_messages << bed.formatted_message
      false
    end

    def error_messages
      @error_messages ||= []
    end

    def valid_robot
      return false unless robot_present_if_required

      return true unless verify_robot? && beds.values.first.labware.present?

      if missing_custom_metadatum_collection || original_robot != robot_barcode
        error_messages << 'Your labware is not on the right robot'
        return false
      end
      true
    end

    def robot_present_if_required
      if require_robot? && robot_barcode.blank?
        error_messages << 'Please scan the robot barcode'
        return false
      end
      true
    end

    def missing_custom_metadatum_collection
      beds.values.first.labware.custom_metadatum_collection.nil?
    end

    def original_robot
      return nil if missing_custom_metadatum_collection

      beds.values.first.labware.custom_metadatum_collection.metadata['created_with_robot']
    end

    def valid_labwares
      beds.transform_values do |bed|
        bed.valid? || bed_error(bed)
      end
    end

    #
    # Returns a hash of bed barcodes and their valid state
    # Also adds any errors describing invalid bed states
    #
    # @return [Hash< String => Boolean>] Hash of boolean indexed by bed barcode
    def valid_relationships
      parents_and_position do |parents, position|
        check_labware_identity(parents, position)
      end.compact
    end

    def bed_class
      Robots::Bed::Base
    end

    def parents_and_position
      recognised_beds.transform_values do |bed|
        next if bed.parents.blank?

        bed.parents.all? do |parent_bed_barcode|
          yield(bed.parent_labware, parent_bed_barcode)
        end
      end
    end

    # Check whether the labware scanned onto the indicated bed
    # matches the expected labwares. Records any errors.
    #
    # @param parents [Array] An array of expected labwares
    # @param position [String] The barcode of the bed expected to contain the labwares
    # @return [Boolean] True if valid, false otherwise
    def check_labware_identity(parents, position)
      if parents.empty?
        check_labware_identity_when_not_expecting_a_labware(position)
      else
        check_labware_identity_when_expecting_a_labware(parents, position)
      end
    end

    # Check whether the indicated bed is valid when we are not expecting anything.
    # Records any errors.
    #
    # @param position [String] The barcode of the bed
    # @return [Boolean] True if valid, false otherwise
    def check_labware_identity_when_not_expecting_a_labware(position)
      # We have not scanned a labware, and no scanned labwares are expected (valid)
      return true if beds[position].labware.nil?

      # We have a shared parent and the shared parent contains a labware, but one of the target beds
      # does not e.g. PhiX tube shared on a robot with multiple transfers (valid)
      return true if beds[position].shared_parent

      # We have scanned a labware, but weren't expecting one (invalid)
      msg = 'Either the labware scanned into this bed should not be here, or the related labware(s) have not been scanned into their beds.'
      error(beds[position], msg)
      false
    end

    # Check whether the indicated bed is valid when we are expecting a specific labware.
    # Records any errors.
    #
    # @param position [String] The barcode of the bed
    # @return [Boolean] True if valid, false otherwise
    # rubocop:disable Metrics/AbcSize
    def check_labware_identity_when_expecting_a_labware(parents, position)
      expected_uuids = parents.map(&:uuid)

      # We have scanned a labware, and it is in the list of expected labwares (valid)
      return true if expected_uuids.include?(beds[position].labware.try(:uuid))

      # filter the list of parents to expected bed labware purpose at this position, e.g. position takes purpose A, filter parents for purpose A
      expected_labwares = parents.filter { |parent| parent.purpose.name == beds[position].purpose }
      msg = if beds[position].labware.nil?
              # We expected a labware but none was scanned
              "Was expected to contain labware barcode #{expected_labwares.map(&:human_barcode).join(',')} but nothing was scanned (empty)."
            else
              # We have scanned an unexpected labware
              "Was expected to contain labware barcode #{expected_labwares.map(&:human_barcode).join(',')} but contains a different labware."
            end
      error(beds[position], msg)
      false
    end
    # rubocop:enable Metrics/AbcSize

    def recognised_beds
      beds.select { |_barcode, bed| bed.recognised? }
    end
  end
  # rubocop:enable Metrics/ClassLength
end
