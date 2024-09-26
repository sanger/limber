# frozen_string_literal: true

# This label class provides attributes for Bioscan tube labels. The labels have
# two stickers, side and cap.
#
# The side contain a 2D barcode image and four text lines.
# * The barcode image contains human barcode.
# * The first line contains parent barcode and well range for PCR2 Pool tube
#   and only the parent parcode for others.
# * The second line contains current tube barcode without prefix and number of
#   pooled samples, the third line contains the labware purpose.
# * The third line contains current tube labware purpose
# # The last line contains date of printing.
#
# The cap contains two text lines.
# * The first contains barcode prefix.
# * The last contains current tube barcode without prefix.
#
# Initially, this arrangement was only intended for Traction compatibility of
# Lib PCR XP (final) tube. However, difficulty of printing 1D barcodes for PCR2
# and Lib PCR tubes made us using 2D barcodes for all three Bioscan tubes.
#
# Only Squix printers are used for printing labels for Bioscan labware from
# Limber. We do not send the print requests to PMB service, instead we send them
# directly to SPrint service, which talks to Squix printers.
#
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

  def first_line
    # Parent barcode followed by well range from labware.name for PCR2 Pool tube.
    match = labware.name.match(/^.+?\s([A-Z]\d{1,2}:[A-Z]\d{1,2})$/)
    return "#{labware.parents[0].barcode.human} #{match[1]}" if match

    # Parent barcode for Lib PCR Pool and Lib PCR XP tubes
    labware.parents[0].barcode.human
  end

  def second_line
    pools_size = @options[:pool_size] || labware.aliquots.count
    "#{barcode_human_without_prefix}, P#{pools_size}"
  end

  def barcode_human_without_prefix
    labware.barcode.human.sub(/\A#{Regexp.escape(labware.barcode.prefix)}/, '')
  end
end
