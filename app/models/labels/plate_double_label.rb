# frozen_string_literal: true

# Prints labels for 384-well plates
class Labels::PlateDoubleLabel < Labels::Base
  def attributes
    {
      right_text: workline_identifier,
      left_text: labware.barcode.human,
      barcode: labware.barcode.machine
    }
  end

  def extra_attributes
    {
      right_text: "#{workline_identifier} #{labware.role} #{labware.purpose.name}",
      left_text: date_today
    }
  end

  def sprint_attributes
    {
      right_text: workline_identifier,
      left_text: labware.barcode.human,
      barcode: labware.barcode.machine,
      extra_right_text: "#{workline_identifier} #{labware.role} #{labware.purpose.name}",
      extra_left_text: date_today
    }
  end

  def default_printer_type
    default_printer_type_for(:plate_double)
  end

  def default_label_template
    default_label_template_for(:plate_double)
  end

  def default_sprint_label_template
    default_sprint_label_template_for(:plate_double)
  end
end
