# frozen_string_literal: true

# Plate label class to print off the QC plate barcode labels from the LCA PBMC plate.
# Specific to the Cardinal pipeline and this plate purpose.
class Labels::PlateLabelLcaPbmc < Labels::PlateLabelBase
  def attributes
    super.merge(barcode: labware.barcode.human)
  end

  def qc_attribute_for_index(index)
    {
      top_left: date_today,
      bottom_left: "#{labware.barcode.human} QC#{index}",
      top_right: labware.stock_plate&.barcode&.human,
      barcode: [labware.barcode.human, "QC#{index}"].compact.join('-')
    }
  end

  def qc_attributes
    [
      qc_attribute_for_index(4),
      qc_attribute_for_index(3),
      qc_attribute_for_index(2),
      qc_attribute_for_index(1)
    ]
  end
end
