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
    # @param expected_labwares [Array] An array of expected labwares
    # @param position [String] The barcode of the bed expected to contain the labwares
    # @return [Boolean] True if valid, false otherwise
    # rubocop:disable Metrics/AbcSize
    def check_labware_identity(expected_labwares, position)
      expected_uuids = expected_labwares.map(&:uuid)

      if expected_uuids.empty?
        # We haven't scanned a labware, and no scanned labwares are expected (valid)
        return true if beds[position].labware.nil?

        # We have a shared parent and the shared parent contains a labware, but one of the target beds
        # does not e.g. PhiX tube shared on a robot with multiple transfers (valid)
        return true if beds[position].shared_parent

        # We've scanned a labware, but weren't expecting one (invalid)
        error(beds[position], 'Unexpected labware scanned, or parent labware has not been scanned.')
      else
        # We've scanned a labware, and it is in the list of expected labwares
        return true if expected_uuids.include?(beds[position].labware.try(:uuid))

        # We've scanned an unexpected labware
        error(beds[position], "Should contain #{expected_labwares.map(&:human_barcode).join(',')}.")
      end
    end
    # rubocop:enable Metrics/AbcSize

    def recognised_beds
      beds.select { |_barcode, bed| bed.recognised? }
    end
  end
  # rubocop:enable Metrics/ClassLength
end
