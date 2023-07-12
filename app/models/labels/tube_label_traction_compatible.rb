# frozen_string_literal: true

# This is the same as a standard Tube label but has a human readable barcode
# instead of the machine barcode.
class Labels::TubeLabelTractionCompatible < Labels::TubeLabel
  def attributes
    d = {
      first_line: first_line,
      second_line: second_line,
      third_line: labware.purpose_name,
      fourth_line: date_today,
      round_label_top_line: labware.barcode.prefix,
      round_label_bottom_line: labware.barcode.number,
      barcode: labware.barcode.human
    }
    binding.pry
    return d
  end

  # Parent barcode for LBSN-9216 Lib PCR Pool XP tube
  # Empty for LBSN-9216 Lib PCR Pool Tube
  # 
  def first_line
    # Parent barcode for LBSN-384 PCR 2 Pool tube
    return labware.parents[0].barcode.human if labware.parents.size = 1
    # Name for LBSN-9216 Lib PCR Pool XP tube
    return labware.name if labware.name&.match? /^.+?\s[A-Z]\d+:[A-Z]\d+$/
    # Parent barcode for LBSN-9216 Lib PCR Pool XP tube
  end

  def second_line
    pools_size = @options[:pool_size] || labware.aliquots.count
    "#{labware.barcode.number}, P#{pools_size}"
  end
end

