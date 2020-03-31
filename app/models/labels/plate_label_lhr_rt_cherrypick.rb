# frozen_string_literal: true

# Plate label class to print off labels for the intermediate Primer Panel PCR plates 1 and 2.
# Specific to the Heron pipeline.
class Labels::PlateLabelLhrRtCherrypick < Labels::PlateLabelBase
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  # NB. labels come off the printer such that listing them here in reverse order is best for the user.
  # NB. 3 characters max for the barcode suffix otherwise the barcode grows too long and
  # intrudes into the test at the right of the label.
  # Elected to use PP1 and PP2 here for Primer Panel subsets 1 and 2.
  def intermediate_attributes
    [
      {
        top_left: date_today,
        bottom_left: labware.barcode.human,
        top_right: labware.stock_plate&.barcode&.human,
        bottom_right: [labware.role, 'LHR PCR 2'].compact.join(' '),
        barcode: [labware.barcode.human, 'PP2'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: labware.barcode.human,
        top_right: labware.stock_plate&.barcode&.human,
        bottom_right: [labware.role, 'LHR PCR 1'].compact.join(' '),
        barcode: [labware.barcode.human, 'PP1'].compact.join('-')
      }
    ]
  end
end
