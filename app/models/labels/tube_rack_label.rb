# frozen_string_literal: true

# Handles generating the parameters the printing from for Tube Racks
class Labels::TubeRackLabel < Labels::Base
  def attributes
    {
      top_left: date_today,
      bottom_left: labware.barcode.human,
      top_right: labware.name,
      bottom_right: labware.purpose_name,
      barcode: labware.barcode.machine
    }
  end

  def default_printer_type
    default_printer_type_for(:plate_a)
  end

  def default_label_template
    default_label_template_for(:plate_a)
  end

  def default_sprint_label_template
    default_sprint_label_template_for(:plate_a)
  end
end
