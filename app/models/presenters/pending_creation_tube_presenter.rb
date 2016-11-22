# frozen_string_literal: true

module Presenters
  class PendingCreationTubePresenter < TubePresenter
    state_machine :state, initial: :pending do
      event :start do
        transition pending: :started
      end

      event :take_default_path do
        transition pending: :passed
      end

      event :pass do
        transition [:pending, :started] => :passed
      end

      event :fail do
        transition [:passed] => :failed
      end

      event :cancel do
        transition [:pending, :started] => :cancelled
      end

      state :pending do
        include Statemachine::StateAllowsChildCreation
        def default_child_purpose
          purpose.children.first
        end
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        include Statemachine::StateAllowsChildCreation
        def default_child_purpose
          purpose.children.last
        end
      end
    end
  end
end
