# frozen_string_literal: true

# Plate label class to print off the QC and intermediate plates from the LTN Al Lib plate.
# Very specific to this particular pipeline and plate purpose. Maybe if we get more like this
# consider refactoring into something more flexible that can use configuration from the plate
# purpose to determine what to print.
class Labels::PlateLabelLtnAlLib < Labels::PlateLabelBase
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  # rubocop:disable Metrics/AbcSize
  def intermediate_attributes
    [
      {
        top_left: date_today,
        bottom_left: labware.barcode.human,
        top_right: labware.stock_plate&.barcode&.human,
        bottom_right: [labware.role, 'LTN Lig'].compact.join(' '),
        barcode: [labware.barcode.human, 'LIG'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: labware.barcode.human,
        top_right: labware.stock_plate&.barcode&.human,
        bottom_right: [labware.role, 'LTN A-tail'].compact.join(' '),
        barcode: [labware.barcode.human, 'ATL'].compact.join('-')
      },
      {
        top_left: date_today,
        bottom_left: labware.barcode.human,
        top_right: labware.stock_plate&.barcode&.human,
        bottom_right: [labware.role, 'LTN Frag'].compact.join(' '),
        barcode: [labware.barcode.human, 'FRG'].compact.join('-')
      }
    ]
  end

  def qc_attributes
    [
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
  # rubocop:enable Metrics/AbcSize
end
