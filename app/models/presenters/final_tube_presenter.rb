# frozen_string_literal: true

module Presenters
  class FinalTubePresenter < TubePresenter
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
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :passed do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::TubeAllowsLibraryPassing
      end

      state :qc_complete, human_name: 'QC Complete' do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::TubeAllowsLibraryPassing
      end

      state :unknown do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      event :qc_complete do
        transition passed: :qc_complete
      end
    end
  end
end
