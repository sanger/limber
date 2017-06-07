# frozen_string_literal: true

class Labels::PlateLabel < Labels::Base
  def attributes
    {
      top_left: date_today,
      bottom_left: "#{labware.barcode.prefix} #{labware.barcode.number}",
      top_right: "#{labware.stock_plate.barcode.prefix}#{labware.stock_plate.barcode.number}",
      bottom_right: "#{labware.label.prefix} #{labware.label.text}",
      barcode: labware.barcode.ean13
    }
  end
end
