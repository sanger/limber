# frozen_string_literal: true

class Labels::PlateLabelXpBase < Labels::PlateLabelBase # rubocop:todo Style/Documentation
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  def qc_label_definitions
    [
      {
        top_left: date_today,
        bottom_left: "#{labware.barcode.human} QC",
        top_right: workline_identifier,
        barcode: "#{labware.barcode.human}-QC"
      }
    ]
  end
end
