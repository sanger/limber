# frozen_string_literal: true

module Presenters
  class QCTubePresenter < TubePresenter
    state_machine :state, initial: :pending do
      event :take_default_path do
        transition pending: :passed
        transition passed: :qc_complete
      end

      event :pass do
        transition [:pending] => :passed
      end

      event :qc_complete do
        transition passed: :qc_complete
      end

      event :mark_as_failed do
        transition [:passed] => :failed
      end

      event :cancel do
        transition [:pending] => :cancelled
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :qc_complete, human_name: 'QC Complete' do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation
          yield if labware.requests.empty?
          nil
        end

        def control_child_links
          yield if labware.requests.present?
          nil
        end

        # Returns the child plate purposes that can be created in the qc_complete state.
        def default_child_purpose
          purpose.children.first
        end
      end
    end
  end
end
