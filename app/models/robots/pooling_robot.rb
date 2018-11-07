# frozen_string_literal: true

module Robots
  class PoolingRobot < Robot
    class Bed < Robot::Bed
      #    self.attributes = %i[api user_uuid purpose states label parents target_state robot]

      attr_accessor :purpose, :states, :label, :parents, :target_state, :robot, :child

      delegate :api, :user_uuid, to: :robot

      def transition
        return if target_state.nil? || plate.nil? # We have nothing to do

        StateChangers.lookup_for(plate.plate_purpose.uuid).new(api, plate.uuid, user_uuid).move_to!(next_state, "Robot #{robot.name} started")
      end

      def next_state
        last_round? ? target_state : states[states.index(plate.state) + 1]
      end

      def last_round?
        plate.creation_transfers.count <= range.max + 1
      end

      def each_parent
        arrayed_transfers = plate.creation_transfers.to_a
        range.each do |i|
          plate_barcode = if arrayed_transfers[i].present?
                            SBCF::SangerBarcode.from_machine(arrayed_transfers[i].source.barcode.ean13)
                          else
                            SBCF::EmptyBarcode.new
                          end
          yield(parents[i], plate_barcode)
        end
      end

      def range
        round = states.index(plate.state)
        size = parents.count / states.count
        (size * round...size * (round + 1))
      end
      private :range
    end

    attr_writer :destination_bed

    def verify(bed_contents, _robot_barcode = nil)
      valid_plates = Hash[bed_contents.map do |bed_id, plate_barcode|
        beds[bed_id].load(plate_barcode)
        [bed_id, beds[bed_id].valid? || bed_error(beds[bed_id])]
      end]

      if bed_contents[destination_bed_id].blank?
        # We don't even have a destination barcode
        valid_plates[destination_bed_id] = false
        error(destination_bed, 'No destination plate barcode provided')
      elsif valid_plates[destination_bed_id]
        # The destination bed is valid, so check its parents are correct
        destination_bed.each_parent do |bed_barcode, expected_barcode|
          scanned_barcode = bed_contents.fetch(bed_barcode, []).first
          valid_plates[bed_barcode] = expected_barcode =~ scanned_barcode
          error(beds[bed_barcode], "Expected to contain #{expected_barcode} not #{scanned_barcode}") unless valid_plates[bed_barcode]
        end
      end
      { beds: valid_plates, valid: error_messages.empty?, message: formatted_message }
    end

    def bed_class(_bed)
      Robots::PoolingRobot::Bed
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
