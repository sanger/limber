#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2015 Genome Research Ltd.
module Presenters
  class MiSeqQCTubePresenter < TubePresenter
    include RobotControlled

    class_attribute    :authenticated_tab_states
    self.authenticated_tab_states =  {
        :pending     => [ 'labware-summary-button', 'labware-state-button' ],
        :started     => [ 'labware-summary-button', 'labware-state-button' ],
        :passed      => [ 'labware-summary-button' ],
        :cancelled   => [ 'labware-summary-button' ],
        :failed      => [ 'labware-summary-button' ]
    }

    state_machine :state, :initial => :pending do
      event :start do
        transition :pending => :started
      end

      event :take_default_path do
        transition :pending => :passed
        transition :passed  => :qc_complete
      end

      event :pass do
        transition [ :pending, :started ] => :passed
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

    end
  end
end
