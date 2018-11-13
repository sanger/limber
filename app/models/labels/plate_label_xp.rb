# frozen_string_literal: true

# Labels::PlateLabelXp
class Labels::PlateLabelXp < Labels::Base
  def attributes
    {
      top_left: date_today,
      bottom_left: labware.barcode.human,
      top_right: labware.stock_plate&.barcode&.human,
      bottom_right: [labware.role, labware.purpose.name].compact.join(' '),
      barcode: labware.barcode.human
    }
  end

  def qc_attributes
    {
      top_left: date_today,
      bottom_left: "#{labware.barcode.human} QC",
      top_right: labware.stock_plate&.barcode&.human,
      barcode: "#{labware.barcode.human}-QC"
    }
  end

  def default_printer_type
    default_printer_type_for(:plate_a)
  end

  def default_label_template
    default_label_template_for(:plate_a)
  end
end
