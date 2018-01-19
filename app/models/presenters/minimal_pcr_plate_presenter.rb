# frozen_string_literal: true

module Presenters
  class MinimalPcrPlatePresenter < MinimalPlatePresenter
    include HasPrimerPanel
    self.summary_partial = 'labware/plates/pcr_summary'
    self.state_transition_name_scope = :pcr

    # summary_items is a hash of a label label, and a symbol representing the
    # method to call to get the value
    self.summary_items = {
      'Barcode' => :barcode,
      'Number of wells' => :number_of_wells,
      'Plate type' => :purpose_name,
      'Primer panel' => :panel_name,
      'Current plate state' => :state,
      'Input plate barcode' => :input_barcode,
      'PCR Cycles' => :pcr_cycles,
      'Created on' => :created_on
    }
  end
end
