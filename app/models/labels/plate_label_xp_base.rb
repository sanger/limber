# frozen_string_literal: true

class Labels::PlateLabelXpBase < Labels::PlateLabelBase # rubocop:todo Style/Documentation
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  # This method contains the information that will be printed in the label
  def qc_attributes
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
