#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
module Presenters
  class PendingCreationPresenter < PlatePresenter
    include Presenters::Statemachine::PendingPlateCreation

    self.aliquot_partial =  'tagged_aliquot'

    self.authenticated_tab_states =  {
      :pending    => [ 'labware-creation-button', 'labware-summary-button', 'labware-state-button' ],
      :passed     => [ 'labware-state-button', 'labware-summary-button' ],
      :cancelled  => [ 'labware-summary-button' ],
      :failed     => [ 'labware-summary-button' ]
    }


  end
end
