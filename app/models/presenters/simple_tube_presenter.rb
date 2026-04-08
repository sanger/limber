# frozen_string_literal: true

module Presenters
  class SimpleTubePresenter < TubePresenter # rubocop:todo Style/Documentation
    include Presenters::FilterMxChildrenCreationBehaviour

    self.summary_items = {
      'Barcode' => :barcode,
      'Tube type' => :purpose_name,
      'Current tube state' => :state,
      'Input plate barcode' => :input_barcode,
      'Stock plate barcode' => :stock_plate_barcode,
      'Created on' => :created_on
    }

    state_machine :state, initial: :pending do
      event :take_default_path, human_name: 'Manual Transfer' do
        transition pending: :passed
      end

      event :pass do
        transition %i[pending started] => :passed
      end

      event :mark_as_failed do
        transition [:passed] => :failed
      end

      event :cancel do
        transition %i[pending started passed] => :cancelled
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :failed do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :passed do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :cancelled do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end
    end

    def stock_plate_barcode
      parent_plate = labware.parents.first
      parent_plate.present? ? stock_plate_barcode_from_metadata(parent_plate.barcode.machine) : 'N/A'
    end
  end
end
