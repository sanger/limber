# frozen_string_literal: true

module Robots
  # Specific to Heron pipeline, sitting between 'LHR RT' plate and 'LHR XP' plate
  # Actual robot program transfers from bed 9 (RT plate) to beds 4&6 (PCR plates)
  class HeronRobotPcrDestinations < HeronRobot
    def valid_relationships
      # overridden to deal with PCR plates having same barcode as parent RT plate
      all_plate_barcodes = beds.values.map { |v| v.barcodes.first }

      valid = true
      unless all_plate_barcodes.uniq.size == 1
        error_messages << 'The PCR plates must have the same barcode as the RT plate, plus a PP suffix.'
        valid = false
      end

      output = {}
      beds.each do |bed_barcode, _bed|
        output[bed_barcode] = valid
      end
      output
    end
  end
end
