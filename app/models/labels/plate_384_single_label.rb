# frozen_string_literal: true

# Prints labels for 384-well plates (single label)
class Labels::Plate384SingleLabel < Labels::Base
  def attributes
    {
      top_left: date_today,
      bottom_left: labware.barcode.human,
      top_right: workline_identifier,
      bottom_right: [labware.role, labware.purpose_name].compact.join(' '),
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
