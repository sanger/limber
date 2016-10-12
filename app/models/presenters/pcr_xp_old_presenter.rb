#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class Presenters::PcrXpOldPresenter < Presenters::PcrXpPresenter

  self.authenticated_tab_states =  {
    :pending     => [ 'labware-summary-button', 'labware-state-button' ],
    :started     => [ 'labware-state-button', 'labware-summary-button' ],
    :passed      => [ 'labware-state-button', 'labware-summary-button', 'well-failing-button', 'labware-creation-button' ],
    :qc_complete => [ 'labware-summary-button', 'labware-state-button' ],
    :cancelled   => [ 'labware-summary-button' ],
    :failed      => [ 'labware-summary-button' ]
  }

end
