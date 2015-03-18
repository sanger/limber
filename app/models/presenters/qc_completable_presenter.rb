#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2015 Genome Research Ltd.
module Presenters
  class QcCompletablePresenter < PlatePresenter
    include Presenters::Statemachine::QcCompletable

    write_inheritable_attribute :authenticated_tab_states, {
      :pending     => [ 'labware-summary-button', 'labware-state-button'   ],
      :started     => [ 'labware-state-button',   'labware-summary-button' ],
      :passed      => [ 'labware-creation-button', 'labware-summary-button', 'labware-state-button', 'well-failing-button' ],
      :qc_complete => [ 'labware-summary-button', 'labware-state-button', 'labware-creation-button' ],
      :cancelled   => [ 'labware-summary-button' ],
      :failed      => [ 'labware-summary-button' ]
    }

  end
end
