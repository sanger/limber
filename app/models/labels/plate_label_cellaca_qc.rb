# frozen_string_literal: true

# Plate label class to print off the QC labels for the cellaca process
# This label template can generate up to 4 qc labels depending on well
# occupancy.
class Labels::PlateLabelCellacaQc < Labels::PlateLabelBase
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  # NB. reverse order so printed in correct sequence
  def qc_label_definitions
    Array.new(max_qc_plates) { |index| qc_label(index) }.reverse
  end

  private

  def qc_label(index)
    {
      top_left: date_today,
      bottom_left: "#{labware.barcode.human} QC#{index + 1}",
      top_right: workline_identifier,
      barcode: [labware.barcode.human, "QC#{index + 1}"].compact.join('-')
    }
  end

  def max_qc_plates
    4 # Always generate 4 QC labels - quick fix for later replacement by Y24-037 (and related)
  end
end
