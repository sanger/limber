# frozen_string_literal: true

module Robots
  # Specific to Heron pipeline, sitting between 'LHR RT' plate and 'LHR XP' plate
  # Actual robot program pools beds 1&2 (PCR plates) onto bed 9 (XP plate)
  # and, optionally, beds 3&4 (PCR plates from second source Cherrypick plate) onto bed 11 (second XP plate)
  # PCR plates are made from LHR RT, but not tracked in LIMS, just have barcodes printed
  # Barcodes consist of LHR RT plate barcode followed by a suffix of -PP1 or -PP2
  class HeronRobotPcrSources < HeronRobot
    def parents_and_position
      # overridden to deal with 2 parents
      recognised_beds.transform_values do |bed|
        next if bed.parents.blank?

        bed.parents.all? do |parent|
          yield(bed.parent_plate, parent)
        end
      end
    end
  end
end
