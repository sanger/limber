# frozen_string_literal: true

# Plate label class to print off 4 QC labels for the cellaca process
class Labels::PlateLabelQuadQc < Labels::PlateLabelBase
  NUMBER_OF_LABELS = 4

  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  # NB. reverse order so printed in correct sequence
  def qc_label_definitions
    Array.new(NUMBER_OF_LABELS) { |index| qc_label(index + 1) }.reverse
  end

  private

  def qc_label(number)
    {
      top_left: date_today,
      bottom_left: "#{labware.barcode.human} QC#{number}",
      top_right: workline_identifier,
      barcode: [labware.barcode.human, "QC#{number}"].compact.join('-')
    }
  end
end
