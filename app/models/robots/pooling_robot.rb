module Robots

  class PoolingRobot < Robot

    class Bed < Robot::Bed
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

    write_inheritable_attribute :attributes, [:api, :user_uuid, :layout, :beds, :name, :destination_bed]

    def verify(bed_contents)
      begin
        destination_bed.load(bed_contents[destination_bed_id])
        return {:beds=>{destination_bed_id => false}, :valid=>false} if destination_bed.plate.nil?
        destination_bed.valid?
      rescue Robots::Robot::Bed::BedError => exception
        return {:beds=>{destination_bed_id => false}, :valid=>false}
      end
      bed_contents[destination_bed_id] = true
      destination_bed.each_parent do |bed_barcode,plate_barcode|
        bed_contents[bed_barcode] = bed_contents[bed_barcode]==plate_barcode
      end
      bed_contents.each {|k,v| bed_contents[k] = false unless v==true}
      {:beds=>bed_contents,:valid=>bed_contents.all?{|_,v| v==true}}
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
