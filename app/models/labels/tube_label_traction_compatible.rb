# frozen_string_literal: true

# This tube label uses human readable barcode instead of the machine barcode
# for Bioscan XP tube for Traction compatibility.
class Labels::TubeLabelTractionCompatible < Labels::Tube1dLabel
  def attributes
    {
      first_line: first_line,
      second_line: second_line,
      third_line: labware.purpose_name,
      fourth_line: date_today,
      round_label_top_line: labware.barcode.prefix,
      round_label_bottom_line: barcode_human_without_prefix,
      barcode: labware.barcode.human
    }
  end

  # Parent barcode
  def first_line
    # Parent barcode for LBSN-9216 Lib PCR Pool XP tube.
    # This is the previous tube barcode.
    labware.parents[0].barcode.human
  end
end
