module Presenters
  class QcPlatePresenter < PlatePresenter

   include Presenters::Statemachine

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'labware-summary-button','labware-state-button' ],
      :started     => [ 'labware-summary-button','labware-state-button' ],
      :passed      => [ 'labware-summary-button' ],
    }

    def control_additional_creation(&block)
      nil
    end

  end
end
