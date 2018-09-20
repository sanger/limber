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

  def default_printer_type
    default_printer_type_for(:plate_a)
  end

  def default_label_template
    default_label_template_for(:plate_a)
  end
end
