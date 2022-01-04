# frozen_string_literal: true

module Presenters
  class CardinalBankStockTubePresenter < SimpleTubePresenter # rubocop:todo Style/Documentation
    self.summary_items = {
      'Barcode' => :barcode,
      'Tube type' => :purpose_name,
      'Current tube state' => :state,
      'Original blood tube' => :stock_blood_tube_barcode,
      'Parent plate barcode' => :parent_barcode,
      'Created on' => :created_on
    }

    def stock_blood_tube_barcode
      if labware.aliquots.present?
        labware.aliquots.first.sample.sample_metadata.supplier_name
      else
        'N/A'
      end
    end

    def parent_barcode
      parent_plate = labware.parents.first
      if parent_plate.present?
        parent_plate.barcode.human
      else
        'N/A'
      end
    end
  end
end
