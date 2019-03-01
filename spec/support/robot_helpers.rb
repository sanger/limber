# frozen_string_literal: true

module RobotHelpers
  def bed_plate_lookup(plate)
    bed_plate_lookup_with_barcode(plate.human_barcode, [plate])
  end

  def bed_plate_lookup_with_barcode(barcode, result)
    allow(Sequencescape::Api::V2::Plate).to receive(:find_all).with(barcode: [barcode]).and_return(result)
  end
end
