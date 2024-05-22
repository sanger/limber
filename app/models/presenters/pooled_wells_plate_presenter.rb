# frozen_string_literal: true

module Presenters
  #
  # The PooledWellsPlatePresenter overrides the way the pooling tab is displayed.
  #
  #
  class PooledWellsPlatePresenter < StandardPresenter
    # The pooling tab is not relevant for this presenter as the wells are already pooled (tab shows future pooling
    # by submission strategy)
    self.pooling_tab = ''

    # Override the samples tab to display additional sample information for the pooled wells
    self.samples_partial = 'plates/pooled_wells_samples_tab'
  end
end
