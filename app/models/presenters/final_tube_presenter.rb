# frozen_string_literal: true

module Presenters
  class FinalTubePresenter
    include Presenter
    include Statemachine::Shared
    include RobotControlled

    class_attribute :summary_items
    self.summary_items = {
      'Barcode' => :barcode,
      'Tube type' => :purpose_name,
      'Current tube state' => :state,
      'Input plate barcode' => :input_barcode,
      'Created on' => :created_on
    }

    class_attribute :labware_class
    self.labware_class = :tube

    self.attributes =  %i[api labware]

    state_machine :state, initial: :pending do
      event :take_default_path, human_name: 'Manual Transfer' do
        transition pending: :passed
      end

      event :pass do
        transition %i[pending started] => :passed
      end

      event :cancel do
        transition %i[pending started] => :cancelled
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :qc_complete, human_name: 'QC Complete' do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :unknown do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      event :qc_complete do
        transition passed: :qc_complete
      end
    end

    def control_child_links
      # Do nothing
    end

    def tube
      labware
    end
    # The state is delegated to the tube
    delegate :state, to: :labware

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    delegate :purpose, to: :labware

    def label
      Labels::TubeLabel.new(labware)
    end

    def sample_count
      labware.aliquots.count
    end

    def labware_form_details(view)
      { url: view.limber_tube_path(labware), as: :tube }
    end
  end
end
