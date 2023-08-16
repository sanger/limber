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
      labware.aliquots.present? ? labware.aliquots.first.sample.sample_metadata.supplier_name : 'N/A'
    end

    def parent_barcode
      parent_plate = labware.parents.first
      parent_plate.present? ? parent_plate.barcode.human : 'N/A'
    end
  end
end
