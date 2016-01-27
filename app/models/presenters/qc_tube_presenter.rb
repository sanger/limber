#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2015 Genome Research Ltd.
module Presenters
  class QCTubePresenter < TubePresenter
    include RobotControlled

    class_inheritable_reader    :authenticated_tab_states
    write_inheritable_attribute :authenticated_tab_states, {
        :pending     => [ 'labware-summary-button', 'labware-state-button' ],
        :started     => [ 'labware-summary-button', 'labware-state-button' ],
        :passed      => [ 'labware-summary-button', 'labware-state-button' ],
        :qc_complete => [ 'labware-summary-button', 'labware-creation-button' ],
        :cancelled   => [ 'labware-summary-button' ],
        :failed      => [ 'labware-summary-button' ]
    }

    state_machine :state, :initial => :pending do
      event :start do
        transition :pending => :started
      end

      event :take_default_path do
        transition :pending => :started
        transition :started => :passed
        transition :passed  => :qc_complete
      end

      event :pass do
        transition [ :pending, :started ] => :passed
      end

      event :qc_complete do
        transition :passed => :qc_complete
      end

      event :fail do
        transition [ :passed ] => :failed
      end

      event :cancel do
        transition [ :pending, :started ] => :cancelled
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        def has_qc_data?; true; end
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :qc_complete, :human_name => 'QC Complete' do
        # Yields to the block if there are child plates that can be created from the current one.
        # It passes the valid child plate purposes to the block.
        def has_qc_data?; true; end

        def control_additional_creation(&block)
          yield unless default_child_purpose.nil? || labware.requests.size > 0
          nil
        end

        def control_child_links(&block)
          yield if labware.requests.size > 0
          nil
        end

        # Yields the valid purpose.
        def valid_purposes
          yield default_child_purpose unless default_child_purpose.nil?
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
