# frozen_string_literal: true

class Labels::PlateLabelHumanBarcode < Labels::Base # rubocop:todo Style/Documentation
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
    default_printer_type_for(:plate_96_2d)
  end

  def default_label_template
    default_label_template_for(:plate_96_2d)
  end

  def default_sprint_label_template
    default_sprint_label_template_for(:plate_96_2d)
  end
end
