# frozen_string_literal: true

module Robots::Bed
  # A bed is a barcoded area of a robot that can receive a plate.
  class Base
    include Form
    # Our robot has beds/rack-spaces
    attr_accessor :purpose, :states, :label, :parent, :target_state, :robot, :child, :display_purpose,
                  :override_class, :parents
    attr_writer :barcodes

    delegate :api, :user_uuid, :plate_includes, :well_order, to: :robot
    delegate :state, to: :plate, allow_nil: true, prefix: true
    delegate :empty?, to: :barcodes

    validates :barcodes, length: { maximum: 1, too_long: 'This bed has been scanned multiple times with different barcodes. Only once is expected.' }
    validates :plate, presence: { message: ->(bed, _data) { "Could not find a plate with the barcode '#{bed.barcode}'." } }, if: :barcode
    validate :correct_plate_purpose, if: :plate
    validate :correct_plate_state, if: :plate

    def recognised?
      true
    end

    def transitions?
      target_state.present?
    end

    def transition
      return if target_state.nil? || plate.nil? # We have nothing to do

      StateChangers.lookup_for(plate.purpose.uuid).new(api, plate.uuid, user_uuid).move_to!(target_state, "Robot #{robot.name} started")
    end

    def purpose_labels
      display_purpose || purpose
    end

    def barcodes
      @barcodes ||= []
    end

    def barcode
      barcodes.first
    end

    def load(barcodes)
      # Ensure we always deal with an array, and any accidental duplicate scans are squashed out
      @barcodes = Array(barcodes).map(&:strip).uniq.reject(&:blank?)
      @plates = if @barcodes.present?
                  Sequencescape::Api::V2::Plate.find_all({ barcode: @barcodes }, includes: plate_includes)
                else
                  []
                end
    end

    def plate
      @plates&.first
    end

    def parent_plate
      return nil if plate.nil?

      parent = plate.parents.first
      return parent if parent

      error("Labware #{plate.human_barcode} doesn't seem to have a parent, and yet one was expected.")
      nil
    end

    def child_plates
      return [] if plate.nil?

      @child_plates ||= plate.wells.sort_by(&well_order).each_with_object([]) do |well, plates|
        next if well.downstream_plates.empty?

        plates << well.downstream_plates.first unless plates.include?(well.downstream_plates.first)
      end
    end

    def formatted_message
      "#{label} - #{errors.full_messages.join('; ')}"
    end

    private

    def correct_plate_purpose
      return true if plate.purpose.name == purpose

      error("Plate #{plate.human_barcode} is a #{plate.purpose.name} not a #{purpose} plate.")
    end

    def correct_plate_state
      return true if states.include?(plate.state)

      error("Plate #{plate.human_barcode} is #{plate.state} when it should be #{states.join(', ')}.")
    end

    def error(message)
      errors.add(:base, message)
      false
    end
  end
end
