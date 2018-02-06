# frozen_string_literal: true

module Presenters
  class SimpleTubePresenter < TubePresenter
    state_machine :state, initial: :pending do
      event :start do
        transition pending: :started
      end

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

      state :passed do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing

        def default_child_purpose
          purpose.children.first
        end
      end
    end

    def active_request_type
      :tube
    end
  end
end
