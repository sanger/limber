# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.
module Presenters
  class PrePcrPlatePresenter < PlatePresenter
    include Presenters::Statemachine

    self.authenticated_tab_states = {
      pending: ['labware-summary-button', 'labware-creation-button'],
      started: ['labware-summary-button'],
      passed: ['labware-creation-button', 'well-failing-button', 'labware-summary-button'],
      cancelled: ['labware-summary-button'],
      failed: ['labware-summary-button']
    }

    state_machine :state, initial: :pending do
      Statemachine::StateTransitions.inject(self)

      state :pending do
        def control_additional_creation
          yield unless default_child_purpose.nil?
          nil
        end

        def valid_purposes
          yield default_child_purpose unless default_child_purpose.nil?
          nil
        end

        def default_child_purpose
          labware.plate_purpose.children.first # ILB_STC_PCR
        end
      end

      state :started do
        StateDoesNotAllowChildCreation
      end

      state :passed do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation
          yield unless default_child_purpose.nil?
          nil
        end

        # Returns the child plate purposes that can be created in the passed state.
        def default_child_purpose
          labware.plate_purpose.children.last # ILB_STC_PCRR
        end

        def valid_purposes
          yield default_child_purpose unless default_child_purpose.nil?
          nil
        end
      end

      state :failed do
        include StateDoesNotAllowChildCreation
      end
      state :cancelled do
        include StateDoesNotAllowChildCreation
      end
    end
  end
end
