# frozen_string_literal: true

class Labels::PlateLabelHumanBarcode < Labels::PlateLabelBase # rubocop:todo Style/Documentation
  def attributes
    {
      top_left: date_today,
      bottom_left: labware.barcode.human,
      top_right: workline_identifier,
      bottom_right: [labware.role, labware.purpose_name].compact.join(' '),
      barcode: labware.barcode.human
    }
  end
end
