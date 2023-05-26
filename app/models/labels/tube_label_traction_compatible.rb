# frozen_string_literal: true

# This is the same as a standard Tube label but has a human readable barcode
# instead of the machine barcode.
class Labels::TubeLabelTractionCompatible < Labels::TubeLabel
  def attributes
    {
      first_line: first_line,
      second_line: second_line,
      third_line: labware.purpose_name,
      fourth_line: date_today,
      round_label_top_line: labware.barcode.prefix,
      round_label_bottom_line: labware.barcode.number,
      barcode: labware.barcode.human
    }
  end
end
