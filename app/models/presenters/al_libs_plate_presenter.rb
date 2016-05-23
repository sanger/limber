#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2015 Genome Research Ltd.
module Presenters
  class AlLibsPlatePresenter < PlatePresenter
    include Presenters::Statemachine

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'labware-summary-button', 'labware-state-button' ],
      :started     => [ 'labware-summary-button', 'labware-state-button' ],
      :passed      => [ 'labware-creation-button', 'labware-state-button', 'labware-summary-button', 'well-failing-button' ],
      :fx_transfer => [ 'labware-summary-button' ],
      :cancelled   => [ 'labware-summary-button' ],
      :failed      => [ 'labware-summary-button' ]
    }

    state_machine :state, :initial => :pending do
      Statemachine::StateTransitions.inject(self)

      state :pending do
        include StateDoesNotAllowChildCreation
      end

      state :started do
        include StateDoesNotAllowChildCreation
      end

      state :fx_transfer do
        include StateDoesNotAllowChildCreation
      end

      state :passed do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def control_additional_creation(&block)
          yield unless default_child_purpose.nil?
          nil
        end

        def valid_purposes
          yield default_child_purpose unless default_child_purpose.nil?
          nil
        end

        # Returns the child plate purposes that can be created in the passed state.
        def default_child_purpose
          # Lib PCR
          labware.plate_purpose.children.first
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
