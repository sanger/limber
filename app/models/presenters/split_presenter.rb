# frozen_string_literal: true

module Presenters
  #
  # The SplitPresenter is used for plates that has beed de-multiplexed and have
  # `stock_barcode` in their metadata. This presenter will show the originating
  # stock barcode as well.
  #
  class SplitPresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    validates_with Validators::SuboptimalValidator

    self.summary_items = {
      'Barcode' => :barcode,
      'Number of wells' => :number_of_wells,
      'Plate type' => :purpose_name,
      'Current plate state' => :state,
      'Input plate barcode' => :stock_plate_barcode,
      'Parent plate barcode' => :input_barcode,
      'PCR Cycles' => :pcr_cycles,
      'Created on' => :created_on
    }

    def stock_plate_barcode
      metadata = PlateMetadata.new(api: api, barcode: labware.barcode.machine).metadata
      barcode = 'N/A'
      barcode = metadata.fetch('stock_barcode', barcode) unless metadata.nil?
      return barcode
    end
  end
end
