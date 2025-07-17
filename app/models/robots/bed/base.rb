# frozen_string_literal: true

module Robots::Bed
  # A bed is a barcoded area of a robot that can receive a labware.
  class Base
    include Form

    # Our robot has beds/rack-spaces
    attr_accessor :purpose, :states, :label, :parents, :target_state, :robot, :child, :shared_parent
    attr_writer :barcodes

    delegate :api, :user_uuid, :well_order, to: :robot
    delegate :state, to: :labware, allow_nil: true, prefix: true
    delegate :empty?, to: :barcodes

    validates :barcodes,
              length: {
                maximum: 1,
                too_long: 'This bed has been scanned multiple times with different barcodes. Only once is expected.'
              }
    validates :labware,
              presence: {
                message: ->(bed, _data) { "Could not find a labware with the barcode '#{bed.barcode}'." }
              },
              if: :barcode
    validate :correct_labware_purpose, if: :labware
    validate :correct_labware_state, if: :labware

    def recognised?
      true
    end

    def error_messages
      errors.full_messages.join(' ')
    end

    def parent=(parent_bed)
      @parents = [parent_bed]
    end

    def parent
      (@parents || []).first
    end

    def transitions?
      target_state.present?
    end

    def transition # rubocop:todo Metrics/AbcSize
      return if target_state.nil? || labware.nil? # We have nothing to do

      StateChangers
        .lookup_for(labware.purpose.uuid)
        .new(api, labware.uuid, user_uuid)
        .move_to!(target_state, "Robot #{robot.name} started")
    end

    def purpose_labels
      Array(purpose).to_sentence(two_words_connector: ' or ', last_word_connector: ' or ')
    end

    def barcodes
      @barcodes ||= []
    end

    def barcode
      barcodes.first
    end

    # overriden in sub-classes of bed to customise what class is used and what is included
    def find_all_labware
      Sequencescape::Api::V2::Labware.find_all({ barcode: @barcodes }, includes: %i[purpose parents])
    end

    def load(barcodes)
      # Ensure we always deal with an array, and any accidental duplicate scans are squashed out
      @barcodes = Array(barcodes).map(&:strip).uniq.compact_blank

      @labware = @barcodes.present? ? find_all_labware : []
    end

    def labware
      @labware&.first
    end

    def parent_labware
      return [] if labware.nil?

      parents = labware.parents
      return parents if parents.present?

      error("Labware #{labware.human_barcode} doesn't seem to have any parents, and yet at least one was expected.")
      []
    end

    def formatted_message
      "#{label} - #{errors.full_messages.join('; ')}"
    end

    private

    def correct_labware_purpose
      return true if Array(purpose).include?(labware.purpose.name)

      error("Labware #{labware.human_barcode} is a #{labware.purpose.name} not a #{purpose_labels} labware.")
    end

    def correct_labware_state
      return true if states.include?(labware.state)

      error("Labware #{labware.human_barcode} is in state #{labware.state} when it should be #{states.join(', ')}.")
    end

    def error(message)
      errors.add(:base, message)
      false
    end
  end
end
