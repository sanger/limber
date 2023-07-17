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
      round_label_bottom_line: barcode_human_without_prefix,
      barcode: labware.barcode.human
    }
  end

  # Parent barcode
  def first_line
    # Parent barcode for LBSN-384 PCR 2 Pool tube.
    # This is the asset name with well range, which corresponds to plate barcode and well range.
    return labware.name if labware.name&.match?(/^.+?\s[A-Z]\d{1,2}:[A-Z]\d{1,2}$/)

    # Parent barcode for LBSN-9216 Lib PCR Pool tube.
    # There are up to 24 parent tubes for this tube. Show the first parent.

    # Parent barcode for LBSN-9216 Lib PCR Pool XP tube.
    # This is the previous tube barcode.
    return labware.parents[0].barcode.human if labware.parents.size == 1
  end

  # Tube ID without prefix followed by number of samples
  def second_line
    pools_size = @options[:pool_size] || labware.aliquots.count
    "#{barcode_human_without_prefix}, P#{pools_size}"
  end

  #
  def barcode_human_without_prefix
    labware.barcode.human.sub(/\A#{Regexp.escape(labware.barcode.prefix)}/, '')
  end
end
