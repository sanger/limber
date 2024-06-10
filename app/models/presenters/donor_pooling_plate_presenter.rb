# frozen_string_literal: true

module Presenters
  # Presenter for the scRNA Core donor pooling plate to validate the required
  # number of cells by study. If other features are necessary in the presenter,
  # they can be added here or the validation can be moved to the new one.
  class DonorPoolingPlatePresenter < StandardPresenter
    validates_with Validators::RequiredNumberOfCellsValidator

    # The pooling tab is not relevant for this presenter as the wells are already pooled (tab shows future pooling
    # by submission strategy)
    self.pooling_tab = ''

    # Override the samples tab to display additional sample information for the pooled wells
    self.samples_partial = 'plates/pooled_wells_samples_tab'
  end
end
