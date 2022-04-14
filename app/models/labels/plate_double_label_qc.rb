# frozen_string_literal: true

# Prints labels for 384 well plates including an extra set for a QC plate
class Labels::PlateDoubleLabelQc < Labels::PlateDoubleLabel
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  # Prints an additional QC plate label
  def qc_attributes
    [
      {
        right_text: workline_identifier,
        left_text: "#{labware.barcode.human} QC",
        barcode: "#{labware.barcode.human}-QC"
      },
      { right_text: "#{workline_identifier} #{labware.role} #{labware.purpose_name} QC", left_text: date_today }
    ]
  end
end
