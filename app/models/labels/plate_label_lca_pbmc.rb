# frozen_string_literal: true

# Plate label class to print off the QC plate barcode labels from the LCA PBMC plate.
# Specific to the Cardinal pipeline and this plate purpose.
class Labels::PlateLabelLcaPbmc < Labels::PlateLabelBase
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  def qc_attributes # rubocop:todo Metrics/MethodLength
    [
      {
        top_left: date_today,
        bottom_left: "#{labware.barcode.human} QC4",
        top_right: labware.stock_plate&.barcode&.human,
        barcode: [labware.barcode.human, 'QC4'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: "#{labware.barcode.human} QC3",
        top_right: labware.stock_plate&.barcode&.human,
        barcode: [labware.barcode.human, 'QC3'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: "#{labware.barcode.human} QC2",
        top_right: labware.stock_plate&.barcode&.human,
        barcode: [labware.barcode.human, 'QC2'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: "#{labware.barcode.human} QC1",
        top_right: labware.stock_plate&.barcode&.human,
        barcode: [labware.barcode.human, 'QC1'].compact.join('-')
      }
    ]
  end
end
