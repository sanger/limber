# frozen_string_literal: true

module Robots
  class Robot::Bed
    include Form

    class BedError < StandardError; end
    # Our robot has beds/rack-spaces
    attr_reader :plate, :error_messages

    class_attribute :attributes
    self.attributes = %i[api user_uuid purpose states label parent target_state robot]

    def initialize(*args)
      @error_messages = []
      super
    end

    def transitions?
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
end
