# frozen_string_literal: true

module Robots
  # Specific to Heron pipeline, sitting between 'LHR RT' plate and 'LHR XP' plate
  # Actual robot program pools beds 1&2 (PCR plates) onto bed 9 (XP plate)
  # and, optionally, beds 3&4 (PCR plates from second source Cherrypick plate) onto bed 11 (second XP plate)
  # PCR plates are made from LHR RT, but not tracked in LIMS, just have barcodes printed
  # Barcodes consist of LHR RT plate barcode followed by a suffix of -PP1 or -PP2
  class HeronRobot < Robot
    def bed_plates=(bed_plates)
      # strip the -PP1 / -PP2 suffix off, so existing method can verify that cherrypick plates exist
      bed_plates.each do |bed_barcode, plate_barcodes|
        plate_barcode = plate_barcodes.first

        processed_plate_barcode = plate_barcode
        if plate_barcode.include?('-PP')
          processed_plate_barcode = plate_barcode.split('-')[0]
          # save the suffix for validation in the bed class
          beds[bed_barcode.strip].plate_barcode_suffix = plate_barcode.split('-')[1]
        end
        beds[bed_barcode.strip].load([processed_plate_barcode])
      end

    end
  end
end
