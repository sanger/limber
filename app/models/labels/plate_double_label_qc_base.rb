# frozen_string_literal: true

# Base class for printing 384 well plate labels including an extra QC set
class Labels::PlateDoubleLabelQcBase < Labels::PlateDoubleLabelBase
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
      {
        right_text: "#{workline_identifier} #{labware.role} #{labware.purpose.name} QC",
        left_text: date_today
      }
    ]
  end
end
