# frozen_string_literal: true

# Prints labels for Bioscan 384-well plates (single label)
class Labels::Plate384SingleLabel < Labels::Base
  def attributes
    {
      top_left: labware.barcode.human,
      bottom_left: labware.purpose_name,
      top_right: date_today,
      bottom_right: labware.workline_identifier,
      barcode: labware.barcode.human
    }
  end

  def default_printer_type
    default_printer_type_for(:plate_384_single)
  end

  def default_label_template
    default_label_template_for(:plate_384_single)
  end

  def default_sprint_label_template
    default_sprint_label_template_for(:plate_384_single)
  end
end
