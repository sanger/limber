#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
module Presenters
  class PcrPresenter < StandardPresenter

    self.aliquot_partial =  'tagged_aliquot'

    self.authenticated_tab_states =  {
      :pending    => [ 'labware-summary-button', 'labware-state-button' ],
      :started_fx => [ 'labware-state-button', 'labware-summary-button' ],
      :started_mj => [ 'labware-state-button', 'labware-summary-button' ],
      :passed     => [ 'labware-creation-button', 'labware-state-button', 'labware-summary-button' ],
      :cancelled  => [ 'labware-summary-button' ],
      :failed     => [ 'labware-summary-button' ]
    }


  end
end
