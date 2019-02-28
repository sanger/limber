# frozen_string_literal: true

module Robots
  class PoolingRobot < Robot
    class Bed < Robot::Bed
      attr_accessor :parents

      def next_state
        last_round? ? target_state : states[states.index(plate.state) + 1]
      end

      def last_round?
        parent_plates.count <= range.max + 1
      end

      def each_parent
        range.each do |i|
          plate_barcode = if parent_plates[i].present?
                            SBCF::SangerBarcode.from_machine(parent_plates[i].barcode.machine)
                          else
                            SBCF::EmptyBarcode.new
                          end
          yield(parents[i], plate_barcode)
        end
      end

      private

      def parent_plates
        @parent_plates ||= plate.wells_in_columns.each_with_object([]) do |well, plates|
          plates << well.upstream_plates.first unless plates.include?(well.upstream_plates.first)
        end
      end

      def range
        round = states.index(plate.state)
        size = parents.count / states.count
        (size * round...size * (round + 1))
      end
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
      Report.new(valid_plates, error_messages.empty?, formatted_message)
    end

    def bed_class
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
