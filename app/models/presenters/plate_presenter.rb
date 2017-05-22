# frozen_string_literal: true

require_dependency 'presenters/presenter'
module Presenters
  class PlatePresenter
    include Presenter
    include PlateWalking
    include RobotControlled
    include Presenters::ExtendedCsv

    class_attribute :labware_class
    self.labware_class = :plate

    attr_accessor :api, :labware
    self.attributes =  %i[api labware]

    class_attribute    :aliquot_partial
    self.aliquot_partial = 'labware/aliquot'

    class_attribute :summary_partial
    self.summary_partial = 'labware/plates/standard_summary'

    class_attribute :printing_partial

    # summary_items is a hash of a label label, and a symbol representing the
    # method to call to get the value
    class_attribute :summary_items
    self.summary_items = {
      'Barcode' => :barcode,
      'Number of wells' => :number_of_wells,
      'Plate type' => :purpose_name,
      'Current plate state' => :state,
      'Input plate barcode' => :input_barcode,
      'Created on' => :created_on
    }

    # This is now generated dynamically by the LabwareHelper
    class_attribute :tab_states

    class_attribute :well_failure_states
    self.well_failure_states = [:passed]

    def number_of_wells
      "#{number_of_filled_wells}/#{total_number_of_wells}"
    end

    def number_of_filled_wells
      plate.wells.count { |w| w.aliquots.present? }
    end

    def total_number_of_wells
      plate.size
    end

    def label_attributes
      { top_left: date_today,
        bottom_left: "#{labware.barcode.prefix} #{labware.barcode.number}",
        top_right: "#{labware.stock_plate.barcode.prefix}#{labware.stock_plate.barcode.number}",
        bottom_right: "#{labware.label.prefix} #{labware.label.text}",
        barcode: labware.barcode.ean13 }
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
      yield if allow_library_passing?
    end

    def tagged?
      first_filled_well = labware.wells.detect { |w| w.aliquots.first }
      first_filled_well && first_filled_well.aliquots.first.tag.identifier.present?
    end

    def control_tube_display
      yield if labware.transfers_to_tubes?
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

    def labware_form_details(view)
      { url: view.limber_plate_path(labware), as: :plate }
    end

    def transfers
      transfers = labware.creation_transfer.transfers
      transfers.sort { |a, b| split_location(a.first) <=> split_location(b.first) }
    end

    def plate
      labware
    end

    def self.lookup_for(labware)
      (presentation_classes = Settings.purposes[labware.plate_purpose.uuid]) || (return UnknownPlateType)
      presentation_classes[:presenter_class].constantize
    end

    def csv_file_links
      [['', "#{Rails.application.routes.url_helpers.limber_plate_path(labware.uuid)}.csv"]]
    end

    def filename(offset = nil)
      "#{labware.barcode.prefix}#{labware.barcode.number}#{offset}.csv".tr(' ', '_')
    end

    private

    # Split a location string into an array containing the row letter
    # and the column number (as a integer) so that they can be sorted.
    def split_location(location)
      match = location.match(/^([A-H])(\d+)/)
      [match[2].to_i, match[1]] # Order by column first
    end
  end
end
