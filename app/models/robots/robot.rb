# frozen_string_literal: true

module Robots
  class Robot
    include Form

    attr_reader :beds
    attr_accessor :api, :user_uuid, :layout, :name, :id, :verify_robot, :class

    alias verify_robot? verify_robot

    def perform_transfer(bed_settings)
      beds.each do |id, bed|
        bed.load(bed_settings[id]) if bed.transitions?
        bed.valid? || raise(Bed::BedError, bed.error_messages)
      end
      beds.values.each(&:transition)
    end

    def error_messages
      @error_messages ||= []
    end

    def error(bed, message)
      error_messages << "#{bed.label}: #{message}"
      false
    end

    def bed_error(bed)
      error_messages << bed.formatted_message
      false
    end

    def formatted_message
      error_messages.join(' ')
    end

    def verify(bed_contents, robot_barcode = nil)
      verified = valid_plates(bed_contents).merge(valid_relationships) { |_k, v1, v2| v1 && v2 }

      if verify_robot? && beds.values.first.plate.present?
        if beds.values.first.plate.custom_metadatum_collection.nil?
          error_messages << 'Your plate is not on the right robot'
          verified['robot'] = false
        elsif beds.values.first.plate.custom_metadatum_collection.metadata['created_with_robot'] != robot_barcode
          error_messages << 'Your plate is not on the right robot'
          verified['robot'] = false
        end
      end

      Report.new(verified, verified.values.all?, formatted_message)
    end

    def beds=(new_beds)
      beds = Hash.new { |_beds, barcode| InvalidBed.new(barcode) }
      new_beds.each do |id, bed|
        beds[id] = bed_class.new(bed.merge(robot: self))
      end
      @beds = beds
    end

    private

    def valid_plates(bed_contents)
      bed_contents.each_with_object({}) do |(bed_id, plate_barcode), states|
        beds[bed_id].load(plate_barcode)
        states[bed_id] = beds[bed_id].valid? || bed_error(beds[bed_id])
      end
    end

    #
    # Returns a hash of bed barcodes and their valid state
    # Also adds any errors describing invalid bed states
    #
    # @return [Hash< String => Boolean>] Hash of boolean indexed by bed barcode
    def valid_relationships
      parents_and_position do |parent, position|
        check_plate_identity(position, parent)
      end.compact
    end

    def bed_class
      Bed
    end

    def parents_and_position
      beds.transform_values do |bed|
        next if bed.parent.nil?

        yield(bed.parent_plate, bed.parent)
      end
    end

    def check_plate_identity(position, expected_plate)
      return true if beds[position].plate.try(:uuid) == expected_plate.try(:uuid)

      message = if expected_plate.present?
                  "Should contain #{expected_plate.human_barcode}."
                else
                  'Could not match labware with expected child.'
                end
      error(beds[position], message)
    end
  end
end
