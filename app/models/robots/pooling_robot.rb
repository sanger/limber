#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module Robots

  class PoolingRobot < Robot

    class Bed < Robot::Bed

      write_inheritable_attribute :attributes, [:api, :user_uuid, :purpose, :states, :label, :parents, :target_state, :robot]

      def transition
        return if target_state.nil? || plate.nil? # We have nothing to do
        StateChangers.lookup_for(plate.plate_purpose.uuid).new(api, plate.uuid, user_uuid).move_to!(next_state,"Robot #{robot.name} started")
      end

      def next_state
        last_round? ? target_state : states[states.index(plate.state)+1]
      end

      def last_round?
        plate.creation_transfers.count <= range.max+1
      end

      def each_parent
        arrayed_transfers = plate.creation_transfers.to_a
        range.each do |i|
          plate_barcode = arrayed_transfers[i].present? ? arrayed_transfers[i].source.barcode.ean13 : nil
          yield(parents[i], plate_barcode)
        end
      end

      def range
        round = states.index(plate.state)
        size = parents.count/states.count
        (size*round...size*(round+1))
      end
      private :range

    end

    write_inheritable_attribute :attributes, [:api, :user_uuid, :layout, :beds, :name, :destination_bed,:id]

    def verify(bed_contents)

      valid_plates = Hash[bed_contents.map do |bed_id,plate_barcode|
        beds[bed_id].load(plate_barcode)
        [bed_id, beds[bed_id].valid?||bed_error(beds[bed_id])]
      end]

      if bed_contents[destination_bed_id].blank?
        # We don't even have a destination barcode
        valid_plates[destination_bed_id] = false
        error(destination_bed,"No destination plate barcode provided")
      elsif valid_plates[destination_bed_id]
        # The destination bed is valid, so check its parents are correct
        destination_bed.each_parent do |bed_barcode,expected_barcode|
          scanned_barcode = bed_contents.fetch(bed_barcode,[]).first
          valid_plates[bed_barcode] = scanned_barcode == expected_barcode
          error(beds[bed_barcode],"Expected to contain #{expected_barcode} not #{scanned_barcode}") unless valid_plates[bed_barcode]
        end
      else
        # We scanned something wrong onto our destination bed.
        # No need to do anything more, we're already marked as invalid
      end
      {:beds=>valid_plates,:valid=>error_messages.empty?,:message=>formatted_message}
    end

    def destination_bed
      beds[@destination_bed]
    end

    def destination_bed_id
      @destination_bed
    end

    def source_beds
      beds.reject[@destination_bed]
    end

  end
end
