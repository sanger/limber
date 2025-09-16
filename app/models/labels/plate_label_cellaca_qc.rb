# frozen_string_literal: true

# Plate label class to print off the QC labels for the cellaca process
# This label template can generate up to 4 qc labels depending on well
# occupancy.
class Labels::PlateLabelCellacaQc < Labels::PlateLabelBase
  COLS_PER_PAGE = 3

  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  # NB. reverse order so printed in correct sequence
  def qc_label_definitions
    max_qc_plates
      .times
      .filter_map do |index|
        # Dividing a column by three maps it to its page
        next if occupied_columns.none? { |col| col / COLS_PER_PAGE == index }

        qc_label(index)
      end
      .reverse
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
    labware.number_of_columns / COLS_PER_PAGE
  end

  def occupied_columns
    @occupied_columns ||=
      labware
        .wells
        .filter_map do |well|
        next if well.empty?

        well.coordinate.first # column
      end
        .uniq
  end
end
