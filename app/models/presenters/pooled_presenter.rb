#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2015 Genome Research Ltd.
module Presenters
  class PooledPresenter < PlatePresenter
    include Presenters::Statemachine
    def plate
      labware
    end

    def walk_source
      PlateWalking::Walker.new(plate_to_walk, plate_to_walk.wells)
    end

    def walk_destination
      PlateWalking::Walker.new(labware, labware.wells)
    end

    Barcode = Struct.new(:prefix,:number,:suffix,:study,:type)

    def prioritized_name(str, max_size)
      # Regular expression to match
      match = str.match(/(DN)(\d+)([[:alpha:]])( )(\w+)(:)(\w+)/)

      # Sets the priorities position matches in the regular expression to dump into the final string. They will be
      # performed with preference on the most right characters from the original match string
      priorities = [7,5,2,6,3,1,4]

      # Builds the final string by adding the matching string using the previous priorities list
      priorities.reduce([]) do |cad_list, value|
        size_to_copy = (max_size) - cad_list.join("").length
        text_to_copy = match[value]
        cad_list[value] = (text_to_copy[[0, text_to_copy.length-size_to_copy].max, size_to_copy])
        cad_list
      end.join("")
    end

    def get_tube_barcodes
      plate.tubes.map do |tube|
        Barcode.new(tube.barcode.prefix,tube.barcode.number,nil,prioritized_name(tube.name, 10),tube.barcode.type)
      end
    end

  end
end
