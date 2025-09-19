# frozen_string_literal: true

module Presenters
  # This Presenter shows the PCR primer panel on the left along with the standard plate layout
  # view and summary information. This version allows you to fail wells on the plate.
  #
  # This was specifically requested by the lab team for the GBS pipleine PCR1 plate so they
  # could fail wells. If well failing functionality was allowed on stock plates in future, that would be a
  # preferable option for them and they could fail the wells on the parent plate, and the PCR1 plate could
  # be returned to using the MinimalPcrPlatePresenter.
  class PcrWithPrimerPanelPlatePresenter < StandardPresenter
    include HasPrimerPanel

    self.summary_partial = 'labware/plates/pcr_with_primer_panel_summary'
    self.state_transition_name_scope = :pcr

    # Initializes `summary_items` with a hash mapping display names to their corresponding plate attributes.
    # Used by the summary panel to display information about the plate in the GUI.
    self.summary_items = {
      'Barcode' => :barcode,
      'Number of wells' => :number_of_wells,
      'Plate type' => :purpose_name,
      'Primer panel' => :panel_name,
      'Current plate state' => :state,
      'Input plate barcode' => :input_barcode,
      'PCR Cycles' => :requested_pcr_cycles,
      'Created on' => :created_on
    }
  end
end
