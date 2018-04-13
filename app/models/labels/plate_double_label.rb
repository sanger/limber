# frozen_string_literal: true

class Labels::PlateDoubleLabel < Labels::Base
  def attributes
    {
      left_text: "#{labware.barcode.prefix} #{labware.barcode.number}",
      right_text: "#{labware.stock_plate.barcode.prefix}#{labware.stock_plate.barcode.number}",
      barcode: labware.barcode.ean13
    }
  end

  def extra_attributes
    {
      left_text: date_today,
      right_text: "#{labware.stock_plate.barcode.prefix}#{labware.stock_plate.barcode.number} #{labware.label.prefix} #{labware.label.text}"
    }
  end
end
