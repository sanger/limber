# frozen_string_literal: true

# This tube label is the same as TubeLabel with some adjustments for Bioscan
# PCR2 Pool and Lib PCR Pool tubes. Unlike TubeLabel, we keep the prefix of
# parent barcode in the first line. It is labware name if it contains parent
# plate barcode and well range; the first parent tube barcode otherwise. The
# barcode field uses EAN13 coding.
class Labels::Tube1dLabel < Labels::TubeLabel
  def attributes
    {
      first_line: first_line,
      second_line: second_line,
      third_line: labware.purpose_name,
      fourth_line: date_today,
      round_label_top_line: labware.barcode.prefix,
      round_label_bottom_line: barcode_human_without_prefix,
      barcode: labware.barcode.ean13
    }
  end

  # Parent barcode
  def first_line
    # Parent barcode for LBSN-384 PCR 2 Pool tube.
    # This is the asset name (plate barcode and well range)
    barcode_and_wells_format = /^.+?\s[A-Z]\d{1,2}:[A-Z]\d{1,2}$/
    return labware.name if labware.name&.match?(barcode_and_wells_format)

    # Parent barcode for LBSN-9216 Lib PCR Pool tube.
    # There are up to 24 parent tubes for this tube. Show the first parent.
    labware.parents[0].barcode.human
  end

  # Tube ID without prefix followed by number of samples
  def second_line
    pools_size = @options[:pool_size] || labware.aliquots.count
    "#{barcode_human_without_prefix}, P#{pools_size}"
  end

  # Human barcode without prefix for the round label.
  def barcode_human_without_prefix
    labware.barcode.human.sub(/\A#{Regexp.escape(labware.barcode.prefix)}/, '')
  end
end
