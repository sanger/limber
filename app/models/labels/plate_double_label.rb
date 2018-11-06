# frozen_string_literal: true

class Labels::PlateDoubleLabel < Labels::Base
  def attributes
    {
      right_text: labware.stock_plate.barcode.human,
      left_text: labware.barcode.human,
      barcode: labware.barcode.ean13
    }
  end

  def extra_attributes
    {
      right_text: "#{labware.stock_plate.barcode.human} #{labware.role} #{labware.purpose.name}",
      left_text: date_today
    }
  end

  def default_printer_type
    default_printer_type_for(:plate_double)
  end

  def default_label_template
    default_label_template_for(:plate_double)
  end
end
