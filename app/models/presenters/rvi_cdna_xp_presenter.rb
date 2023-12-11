# frozen_string_literal: true

module Presenters
  # Used for RVI cDNA XP plates. Used for a custom 'Manual Transfer' state transition.
  # N.B. 'Manual Transfer' is used for the RVI BCL pipeline for the cDNA XP Plate because the plates
  # are inaccessible in the bed at the time of transfer so cannot be transferred via
  # bed verifications. Also we cannot set its state to 'Passed' on initial bed verification
  # because there are steps on other plates that need to be completed before the cDNA XP Plate can be transferred.
  # and we do not want to misreport the plate being passed if an issue arises with the steps before hand.
  class RviCdnaXpPresenter < PlatePresenter
    include Statemachine::Shared

    # Same state machine as permissive plate presenter, but with a custom 'Manual Transfer' state transition.
    state_machine :state, initial: :pending do
      event :take_default_path, human_name: 'Manual Transfer' do
        transition pending: :started
        transition started: :passed
      end

      event :transfer do
        transition %i[pending started] => :passed
      end

      event :cancel do
        transition %i[pending started passed] => :cancelled
      end

      # We use `fail_labware` here as `fail` is defined on Object (its an alias for `raise`)
      # Statemachines ends up throwing a warning, which while we can disable, we're probably
      # safer avoiding the conflict, especially as we don't actually call these methods directly
      # anyway.
      event :fail_labware, human_name: 'Fail' do
        transition %i[pending started passed] => :failed
      end

      # These are the states, which are really the only things we need ...
      state :pending do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :started do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :processed_1 do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :processed_2 do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :processed_3 do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :passed do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :qc_complete, human_name: 'QC Complete' do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :cancelled do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :failed do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end
    end
    validates_with Validators::SuboptimalValidator
    validates_with Validators::ActiveRequestValidator
  end
end
