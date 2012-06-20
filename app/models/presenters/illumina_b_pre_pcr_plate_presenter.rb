module Presenters
  class IlluminaBPrePcrPlatePresenter < PlatePresenter
    include Presenters::Statemachine

    state_machine :state, :initial => :pending do
      Statemachine::StateTransitions.inject(self)

      state :pending do
        include StateDoesNotAllowChildCreation

      end
      state :started do
        include StateDoesNotAllowChildCreation
      end

      state :passed do

      end
      state :failed do

      end
      state :cancelled do

      end
    end
    write_inheritable_attribute :authenticated_tab_states, {
      :pending    =>  [ 'summary-button'],
      :started    =>  [ 'summary-button'],
      :passed     =>  [ 'summary-button', 'well-failing-button'],
      :cancelled  =>  [ 'summary-button' ],
      :failed     =>  [ 'summary-button' ]
    }
  end
end
