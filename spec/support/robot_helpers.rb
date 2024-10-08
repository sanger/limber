# frozen_string_literal: true

module RobotHelpers
  def bed_labware_lookup(labware, includes = %i[purpose parents])
    bed_labware_lookup_with_barcode(labware.human_barcode, [labware], includes)
  end

  def bed_labware_lookup_with_barcode(barcode, result, includes = %i[purpose parents])
    allow(Sequencescape::Api::V2::Labware).to receive(:find_all).with(
      { barcode: Array(barcode) },
      includes:
    ).and_return(result)
  end

  def bed_plate_lookup(plate, includes = %i[purpose parents])
    bed_plate_lookup_with_barcode(plate.human_barcode, [plate], includes)
  end

  def bed_plate_lookup_with_barcode(barcode, result, includes = %i[purpose parents])
    allow(Sequencescape::Api::V2::Plate).to receive(:find_all).with({ barcode: Array(barcode) }, includes:).and_return(
      result
    )
  end
end
