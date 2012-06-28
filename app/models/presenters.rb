module Presenters
  module Presenter
    def self.included(base)
      base.class_eval do
        include Forms::Form
        write_inheritable_attribute :page, 'show'
      end
    end

    def save!
    end
  end

  class PlatePresenter
    include Presenter
    include PlateWalking

    write_inheritable_attribute :attributes, [ :api, :plate ]

    class_inheritable_reader    :aliquot_partial
    write_inheritable_attribute :aliquot_partial, 'lab_ware/aliquot'

    class_inheritable_reader    :summary_partial
    write_inheritable_attribute :summary_partial, 'lab_ware/plates/standard_summary'

    class_inheritable_reader    :additional_creation_partial
    write_inheritable_attribute :additional_creation_partial, 'lab_ware/plates/child_plate_creation'

    class_inheritable_reader :printing_partial

    class_inheritable_reader    :tab_views
    write_inheritable_attribute :tab_views, {
      'summary-button'        => ['plate-summary', 'plate-printing' ],
      'plate-creation-button' => [ 'plate-summary', 'plate-creation' ],
      'plate-QC-button'       => [ 'plate-summary', 'plate-creation' ],
      'plate-state-button'    => [ 'plate-summary', 'plate-state' ],
      'well-failing-button'   => [ 'well-failing' ]
    }

    class_inheritable_reader    :tab_states
    write_inheritable_attribute :tab_states, {
      :pending    =>  ['summary-button'],
      :started    =>  ['summary-button'],
      :passed     =>  ['summary-button'],
      :cancelled  =>  ['summary-button']
    }

    class_inheritable_reader    :authenticated_tab_states
    write_inheritable_attribute :authenticated_tab_states, {
        :pending    =>  [ 'summary-button', 'plate-state-button' ],
        :started    =>  [ 'plate-state-button', 'summary-button' ],
        :passed     =>  [ 'plate-creation-button','summary-button', 'well-failing-button', 'plate-state-button' ],
        :cancelled  =>  [ 'summary-button' ],
        :failed     =>  [ 'summary-button' ]
    }

    def plate_to_walk
      self.plate
    end

    def lab_ware
      self.plate
    end

    def control_worksheet_printing(&block)
      yield
      nil
    end

    def lab_ware_form_details(view)
      { :url => view.illumina_b_plate_path(self.plate), :as  => :plate }
    end

    def transfers
      transfers = self.plate.creation_transfer.transfers
      transfers.sort {|a,b| split_location(a.first) <=> split_location(b.first) }
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

      def initialize(plate)
        super("Unknown plate type #{plate.plate_purpose.name.inspect}")
        @plate = plate
      end
    end

    def self.lookup_for(plate)
      plate_details = Settings.plate_purposes[plate.plate_purpose.uuid] or raise UnknownPlateType, plate
      plate_details[:presenter_class].constantize
    end
  end
end
