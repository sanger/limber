# frozen_string_literal: true
module Robots
  class Robot
    include Forms::Form

    class Bed
      include Forms::Form

      class BedError < StandardError; end
      # Our robot has beds/rack-spaces
      attr_reader :plate, :error_messages

      class_attribute :attributes
      self.attributes = [:api, :user_uuid, :purpose, :states, :label, :parent, :target_state, :robot]

      def initialize(*args)
        @error_messages = []
        super
      end

      def has_transition?
        @target_state.present?
      end

      def transition
        return if target_state.nil? || plate.nil? # We have nothing to do
        StateChangers.lookup_for(plate.plate_purpose.uuid).new(api, plate.uuid, user_uuid).move_to!(target_state, "Robot #{robot.name} started")
      end

      def error(message)
        error_messages << message
        false
      end
      private :error

      def purpose_labels
        purpose
      end

      def valid?
        if @barcode == :multiple
          error('This bed has been scanned multiple times with different barcodes. Only once is expected.')
        elsif plate.nil? # The bed is empty or untested
          @barcode.nil? || error("Could not find a plate with the barcode #{@barcode}.")
        elsif plate.plate_purpose.uuid != Settings.purpose_uuids[purpose]
          error("Plate #{plate.barcode.prefix}#{plate.barcode.number} is a #{plate.plate_purpose.name} not a #{purpose} plate.")
        elsif !states.include?(plate.state) # The plate is in the wrong state
          error("Plate #{plate.barcode.prefix}#{plate.barcode.number} is #{plate.state} when it should be #{states.join(', ')}.")
        else
          true
        end
      end

      def load(barcodes)
        barcodes = Array(barcodes).uniq.reject(&:blank?) # Ensure we always deal with an array, and any accidental duplicate scans are squashed out
        if barcodes.length > 1 # If we have multiple barcodes, just give up now.
          @barcode = :multiple
        else
          @barcode = barcodes.first
          begin
            @plate = api.search.find(Settings.searches['Find assets by barcode']).first(barcode: @barcode) unless @barcode.nil?
          rescue Sequencescape::Api::ResourceNotFound
            @plate = nil
          end
        end
      end

      def parent_plate
        return nil if recieving_labware.nil?
        begin
          api.search.find(Settings.searches['Find source assets by destination asset barcode']).first(barcode: recieving_labware.barcode.ean13)
        rescue Sequencescape::Api::ResourceNotFound
          error("Labware #{recieving_labware.barcode.prefix}#{recieving_labware.barcode.number} doesn't seem to have a parent, and yet one was expected.")
          nil
        end
      end

      alias recieving_labware plate

      def formatted_message
        "#{label} - #{error_messages.join(' ')}"
      end
    end

    class InvalidBed
      def initialize(barcode)
        @barcode = barcode
      end

      def load(_); end

      def formatted_message
        match = /[0-9]{12,13}/.match(@barcode)
        match ? "Bed with barcode #{@barcode} is not expected to contain a tracked plate." :
                "#{@barcode} does not appear to be a valid bed barcode."
      end

      def valid?
        false
      end
    end

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
    self.attributes = [:api, :user_uuid, :layout, :beds, :name, :id, :verify_robot]

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

      { beds: verified, valid: verified.all? { |_, v| v }, message: formatted_message }
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
