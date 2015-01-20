module Presenters

  class LocationError < StandardError; end

  module Presenter
    def self.included(base)
      base.class_eval do
        include Forms::Form
        write_inheritable_attribute :page, 'show'

        class_inheritable_reader :csv
        write_inheritable_attribute :csv, 'show'

        def has_qc_data?; false; end
      end
    end

    def save!
    end

    def default_printer_uuid
      unless location == :unknown
        @default_printer_uuid ||= Settings.printers[location][Settings.purposes[purpose.uuid].default_printer_type]
      end
      @default_printer_uuid
    end

    def default_label_count
      @default_label_count ||= Settings.printers['default_count']
    end

    def printer_limit
      @printer_limit ||= Settings.printers['limit']
    end

    def suitable_labware
      yield
    end

    def errors
      nil
    end

    def label_type
      nil
    end

  end

  class PlatePresenter
    include Presenter
    include PlateWalking

    class_inheritable_reader :labware_class
    write_inheritable_attribute :labware_class, :plate

    write_inheritable_attribute :attributes, [ :api, :labware ]

    class_inheritable_reader    :aliquot_partial
    write_inheritable_attribute :aliquot_partial, 'labware/aliquot'

    class_inheritable_reader    :summary_partial
    write_inheritable_attribute :summary_partial, 'labware/plates/standard_summary'

    class_inheritable_reader    :additional_creation_partial
    write_inheritable_attribute :additional_creation_partial, 'labware/plates/child_plate_creation'

    class_inheritable_reader :printing_partial

    class_inheritable_reader    :tab_views
    write_inheritable_attribute :tab_views, {
      'labware-summary-button'          => [ 'labware-summary', 'plate-printing' ],
      'labware-creation-button' => [ 'labware-summary', 'plate-creation' ],
      'labware-QC-button'       => [ 'labware-summary', 'plate-creation' ],
      'labware-state-button'    => [ 'labware-summary', 'plate-state'    ],
      'well-failing-button'     => [ 'well-failing', 'well-failing-instructions' ]
    }

    # This is now generated dynamically by the LabwareHelper
    class_inheritable_reader    :tab_states

    class_inheritable_reader    :authenticated_tab_states
    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'labware-summary-button', 'labware-state-button'                           ],
        :started    =>  [ 'labware-state-button', 'labware-summary-button'                           ],
        :passed     =>  [ 'labware-creation-button', 'labware-state-button', 'labware-summary-button' ],
        :cancelled  =>  [ 'labware-summary-button' ],
        :failed     =>  [ 'labware-summary-button' ]
    }

    class_inheritable_reader    :robot_controlled_states
    write_inheritable_attribute :robot_controlled_states, {
    }

    def label_type
      yield "custom-labels"
    end

    def robot_name
      robot_controlled_states[labware.state.to_sym]
    end

    def robot_exists?
      (!robot_name.nil?) && Settings.robots[location][robot_name].present?
    end

    def statechange_link(view)
      robot_exists? ? "#{view.robot_path(robot_name)}/#{location}" : '#'
    end

    def statechange_label
      robot_exists? ? "Bed verification" : 'Move plate to next state'
    end


    def plate_to_walk
      self.labware
    end

    def location
      Settings.locations[labware.location]||:unknown
    end

    def suitable_labware
      yield unless location == :unknown
    end

    def errors
      location == :unknown ? "Plate has not been scanned into an appropriate freezer" : nil
    end

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    def purpose
      labware.plate_purpose
    end

    def allow_plate_label_printing?; true end

    def label_text
      "#{labware.label.prefix} #{labware.label.text}"
    end

    def control_worksheet_printing(&block)
      yield
      nil
    end

    def labware_form_details(view)
      { :url => view.illumina_b_plate_path(self.labware), :as  => :plate }
    end

    def transfers
      transfers = self.labware.creation_transfer.transfers
      transfers.sort {|a,b| split_location(a.first) <=> split_location(b.first) }
    end

    def qc_owner
      labware
    end

    # Split a location string into an array containing the row letter
    # and the column number (as a integer) so that they can be sorted.
    def split_location(location_string)
      match = location_string.match(/^([A-H])(\d+)/)
      [ match[2].to_i, match[1] ]  # Order by column first
    end
    private :split_location

    class UnknownPlateType < StandardError
      attr_reader :plate

      def errors
        "Unknown plate type #{plate.plate_purpose.name.inspect}. Perhaps you are using the wrong pipeline application?"
      end

      def suitable_labware; false; end

      def initialize(opts)
        @plate = opts[:labware]
      end
    end

    def self.lookup_for(labware)
      presentation_classes = Settings.purposes[labware.plate_purpose.uuid] or return UnknownPlateType
      presentation_classes[:presenter_class].constantize
    end

    def csv_file_links
      [["","#{Rails.application.routes.url_helpers.illumina_b_plate_path(labware.uuid)}.csv"]]
    end

    def filename
      false
    end

  end
end
