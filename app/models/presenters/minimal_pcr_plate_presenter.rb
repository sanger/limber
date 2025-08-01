# frozen_string_literal: true

module Presenters
  class MinimalPcrPlatePresenter < MinimalPlatePresenter # rubocop:todo Style/Documentation
    include HasPrimerPanel
    include Presenters::Statemachine::FeatureInStates

    self.summary_partial = 'labware/plates/pcr_summary'
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
