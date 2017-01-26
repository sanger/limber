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

      event :fail do
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
          yield unless default_child_purpose.nil? || !labware.requests.empty?
          nil
        end

        def control_child_links
          yield unless labware.requests.empty?
          nil
        end

        # Yields the valid purpose.
        def valid_purposes
          yield default_child_purpose unless default_child_purpose.nil?
          nil
        end

        # Returns the child plate purposes that can be created in the qc_complete state.
        def default_child_purpos
          purpose.children.first
        end
      end
    end
  end
end
