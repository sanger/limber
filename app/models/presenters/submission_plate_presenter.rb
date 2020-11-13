# frozen_string_literal: true

module Presenters
  #
  # The StandardPresenter is used for the majority of plates. It shows a preview
  # of the plate itself, and permits state changes, well failures and child
  # creation when passed.
  #
  class SubmissionPlatePresenter < PlatePresenter
    include Presenters::StateChangeless

    self.summary_items = {
      'Barcode' => :barcode,
      'Number of wells' => :number_of_wells,
      'Plate type' => :purpose_name,
      'Current plate state' => :state,
      'Input plate barcode' => :input_barcode,
      'Created on' => :created_on
    }
  end
end
