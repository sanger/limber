# frozen_string_literal: true

class Labels::PlateLabelBase < Labels::Base # rubocop:todo Style/Documentation
  def attributes
    {
      top_left: date_today,
      bottom_left: labware.barcode.human,
      top_right: workline_identifier,
      bottom_right: [labware.role, labware.purpose.name].compact.join(' '),
      barcode: labware.barcode.machine
    }
  end

  def default_printer_type
    default_printer_type_for(:plate_a)
  end

  def default_label_template
    default_label_template_for(:plate_a)
  end
end
