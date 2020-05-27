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

    def plate_includes
      %i[purpose parents]
    end

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
      verified = valid_plates.merge(valid_relationships) { |_k, v1, v2| v1 && v2 }
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

    def bed_plates=(bed_plates)
      bed_plates.each do |bed_barcode, plate_barcodes|
        beds[bed_barcode.strip].load(plate_barcodes)
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

      return true unless verify_robot? && beds.values.first.plate.present?

      if missing_custom_metadatum_collection || original_robot != robot_barcode
        error_messages << 'Your plate is not on the right robot'
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
      beds.values.first.plate.custom_metadatum_collection.nil?
    end

    def original_robot
      return nil if missing_custom_metadatum_collection

      beds.values.first.plate.custom_metadatum_collection.metadata['created_with_robot']
    end

    def valid_plates
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
        check_plate_identity(parents, position)
      end.compact
    end

    def bed_class
      Robots::Bed::Base
    end

    def parents_and_position
      recognised_beds.transform_values do |bed|
        next if bed.parents.blank?

        bed.parents.all? do |parent_bed_barcode|
          yield(bed.parent_plates, parent_bed_barcode)
        end
      end
    end

    # Check whether the plate scanned onto the indicated bed
    # matches the expected plates. Records any errors.
    #
    # @param expected_plates [Array] An array of expected plates
    # @param position [String] The barcode of the bed expected to contain the plates
    # @return [Boolean] True if valid, false otherwise
    def check_plate_identity(expected_plates, position)
      expected_uuids = expected_plates.map(&:uuid)
      # We haven't scanned a plate, and no scanned plates are expected
      return true if expected_uuids.empty? && beds[position].plate.nil?
      # We've scanned a plate, and its in the list of expected plates
      return true if expected_uuids.include?(beds[position].plate.try(:uuid))

      # At this point something is wrong
      message = if expected_plates.present?
                  # We've scanned an unexpected plate
                  "Should contain #{expected_plates.map(&:human_barcode).join(',')}."
                else
                  # We've scanned a plate, but weren't expecting one.
                  'Unexpected plate scanned, or parent plate has not been scanned.'
                end
      error(beds[position], message)
    end

    def recognised_beds
      beds.select { |_barcode, bed| bed.recognised? }
    end
  end
  # rubocop:enable Metrics/ClassLength
end
