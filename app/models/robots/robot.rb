# frozen_string_literal: true

module Robots
  class Robot
    include Form

    def self.find(options)
      robot_settings = Settings.robots[options[:id]]
      raise ActionController::RoutingError, "Robot #{options[:name]} Not Found" if robot_settings.nil?
      robot_class = (robot_settings[:class] || 'Robots::Robot').constantize
      robot_class.new(robot_settings.merge(options))
    end

    def self.each_robot
      Settings.robots.each do |key, config|
        yield key, config[:name]
      end
    end

    class_attribute :attributes
    self.attributes = %i[api user_uuid layout beds name id verify_robot]

    def perform_transfer(bed_settings)
      beds.each do |id, bed|
        bed.load(bed_settings[id]) if bed.has_transition?
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

    def verify_robot?
      verify_robot
    end

    def verify(bed_contents, robot_barcode = nil)
      verified = valid_plates(bed_contents).merge(valid_parents) { |_k, v1, v2| v1 && v2 }

      if verify_robot? && beds.values.first.plate.present?
        if beds.values.first.plate.custom_metadatum_collection.uuid.nil?
          error_messages << 'Your plate is not on the right robot'
          verified['robot'] = false
        elsif beds.values.first.plate.custom_metadatum_collection.metadata['created_with_robot'] != robot_barcode
          error_messages << 'Your plate is not on the right robot'
          verified['robot'] = false
        end
      end

      Report.new(verified, verified.values.all?, formatted_message)
    end

    private

    def valid_plates(bed_contents)
      Hash[bed_contents.map do |bed_id, plate_barcode|
        beds[bed_id].load(plate_barcode)
        [bed_id, beds[bed_id].valid? || bed_error(beds[bed_id])]
      end]
    end

    def valid_parents
      Hash[parents_and_position do |parent, position|
        beds[position].plate.try(:uuid) == parent.try(:uuid) || error(beds[position], parent.present? ?
          "Should contain #{parent.barcode.prefix}#{parent.barcode.number}." :
          'Could not match labware with expected child.')
      end.compact]
    end

    def beds=(new_beds)
      beds = ActiveSupport::OrderedHash.new { |_beds, barcode| InvalidBed.new(barcode) }
      new_beds.each do |id, bed|
        beds[id] = bed_class(bed).new(bed.merge(api: api, user_uuid: user_uuid, robot: self))
      end
      @beds = beds
    end

    def bed_class(_bed)
      self.class::Bed
    end

    def parents_and_position
      beds.map do |id, bed|
        next if bed.parent.nil?
        result = yield(bed.parent_plate, bed.parent)
        [id, result]
      end
    end
  end
end
