# frozen_string_literal: true

module Presenters
  class TubePresenter
    include Presenter
    include Statemachine::Shared
    include RobotControlled

    class_attribute :labware_class
    self.labware_class = :tube

    self.attributes =  %i[api labware]

    class_attribute :tab_states

    class_attribute :summary_items
    self.summary_items = {
      'Barcode' => :barcode,
      'Tube type' => :purpose_name,
      'Current tube state' => :state,
      'Input plate barcode' => :input_barcode,
      'Created on' => :created_on
    }

    def label
      Labels::TubeLabel.new(labware)
    end

    def control_child_links(&block)
      # Mostly, no.
    end

    # The state is delegated to the tube
    delegate :state, to: :labware

    def sample_count
      labware.aliquots.count
    end

    def tube
      labware
    end

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    delegate :purpose, to: :labware

    def labware_form_details(view)
      { url: view.limber_tube_path(labware), as: :tube }
    end
  end
end
