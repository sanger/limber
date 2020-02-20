# frozen_string_literal: true

class Labels::PlateLabelXpBase < Labels::PlateLabelBase
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  def qc_attributes
    [
      {
        top_left: date_today,
        bottom_left: "#{labware.barcode.human} QC",
        top_right: labware.stock_plate&.barcode&.human,
        barcode: "#{labware.barcode.human}-QC"
      }
    ]
  end
end
