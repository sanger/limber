# frozen_string_literal: true

module Robots
  # Specific to Heron pipeline, sitting between 'LHR RT' plate and 'LHR XP' plate
  # Actual robot program pools beds 1&2 (PCR plates) onto bed 9 (XP plate)
  # and, optionally, beds 3&4 (PCR plates from second source Cherrypick plate) onto bed 11 (second XP plate)
  # PCR plates are made from LHR RT, but not tracked in LIMS, just have barcodes printed
  # Barcodes consist of LHR RT plate barcode followed by a suffix of -PP1 or -PP2
  class HeronRobotPcrDestinations < HeronRobot

    def valid_relationships
      # overridden to deal with PCR plates having same barcode as parent RT plate
      all_plate_barcodes = beds.values.map { |v| v.barcodes.first }

      valid = true
      unless all_plate_barcodes.uniq.size === 1
        error_messages << "The PCR plates must have the same barcode as the RT plate, plus a PP suffix."
        valid = false
      end

      output = {}
      beds.each do |bed_barcode, bed|
        output[bed_barcode] = valid
      end
      output
    end
  end
end