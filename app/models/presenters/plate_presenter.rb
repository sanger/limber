# frozen_string_literal: true
module Presenters
  class PlatePresenter
    include Presenter
    include PlateWalking
    include RobotControlled

    class_attribute :labware_class
    self.labware_class = :plate

    attr_accessor :api, :labware
    self.attributes =  [:api, :labware]

    class_attribute    :aliquot_partial
    self.aliquot_partial = 'labware/aliquot'

    class_attribute :summary_partial
    self.summary_partial = 'labware/plates/standard_summary'

    class_attribute :additional_creation_partial
    self.additional_creation_partial = 'labware/plates/child_plate_creation'

    class_attribute :printing_partial

    class_attribute :tab_views
    self.tab_views = {
      'labware-summary-button'  => ['labware-summary', 'plate-printing'],
      'labware-creation-button' => ['labware-summary', 'plate-creation'],
      'labware-QC-button'       => ['labware-summary', 'plate-creation'],
      'labware-state-button'    => ['labware-summary', 'plate-state'],
      'well-failing-button'     => ['well-failing', 'well-failing-instructions']
    }

    # This is now generated dynamically by the LabwareHelper
    class_attribute    :tab_states

    class_attribute    :authenticated_tab_states
    self.authenticated_tab_states = {
      pending: ['labware-summary-button', 'labware-state-button'],
      started: ['labware-state-button', 'labware-summary-button'],
      passed: ['labware-creation-button', 'labware-state-button', 'labware-summary-button'],
      cancelled: ['labware-summary-button'],
      failed: ['labware-summary-button']
    }

    def additional_creation_partial
      case default_child_purpose.asset_type
      when 'plate' then 'labware/plates/child_plate_creation'
      when 'tube' then 'labware/tube/child_tube_creation'
      else self.class.additional_creation_partial
      end
    end

    def default_statechange_label
      'Move plate to next state'
    end

    def label_name
      "#{labware.stock_plate.barcode.prefix}#{labware.stock_plate.barcode.number}"
    end

    def plate_to_walk
      labware
    end

    def suitable_labware
      yield
    end

    def errors
      nil
    end

    def control_library_passing
      yield if tagged?
    end

    def tagged?
      first_filled_well = labware.wells.detect { |w| w.aliquots.first }
      first_filled_well && first_filled_well.aliquots.first.tag.identifier.present?
    end

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    def purpose
      labware.plate_purpose
    end

    def allow_plate_label_printing?
      true
    end

    def label_text
      "#{labware.label.prefix} #{labware.label.text}"
    end

    def labware_form_details(view)
      { url: view.limber_plate_path(labware), as: :plate }
    end

    def transfers
      transfers = labware.creation_transfer.transfers
      transfers.sort { |a, b| split_location(a.first) <=> split_location(b.first) }
    end

    def qc_owner
      labware
    end

    def plate
      labware
    end

    # Split a location string into an array containing the row letter
    # and the column number (as a integer) so that they can be sorted.
    def split_location(location)
      match = location.match(/^([A-H])(\d+)/)
      [match[2].to_i, match[1]] # Order by column first
    end
    private :split_location

    class UnknownPlateType < StandardError
      attr_reader :plate

      def errors
        "Unknown plate type #{plate.plate_purpose.name.inspect}. Perhaps you are using the wrong pipeline application?"
      end

      def suitable_labware
        false
      end

      def initialize(opts)
        @plate = opts[:labware]
      end
    end

    def self.lookup_for(labware)
      (presentation_classes = Settings.purposes[labware.plate_purpose.uuid]) || (return UnknownPlateType)
      presentation_classes[:presenter_class].constantize
    end

    def csv_file_links
      [['', "#{Rails.application.routes.url_helpers.limber_plate_path(labware.uuid)}.csv"]]
    end

    def filename
      false
    end
  end
end
