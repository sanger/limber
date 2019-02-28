# frozen_string_literal: true

module Robots
  class PoolingRobot < Robot
    attr_writer :destination_bed

    def valid_relationships
      verified = {}
      if destination_bed.barcode.blank?
        # We don't even have a destination barcode
        verified[destination_bed_id] = false
        error(destination_bed, 'No destination plate barcode provided')
      elsif destination_bed.valid?
        # The destination bed is valid, so check its parents are correct
        destination_bed.each_parent do |bed_barcode, expected_barcode|
          scanned_barcode = beds.fetch(bed_barcode).barcode
          verified[bed_barcode] = expected_barcode =~ scanned_barcode
          unless verified[bed_barcode]
            error(beds[bed_barcode],
                  "Expected to contain #{expected_barcode} not #{scanned_barcode}")
          end
        end
      end
      verified
    end

    def bed_class
      Robots::Bed::Pooling
    end

    def destination_bed
      beds[@destination_bed]
    end

    def destination_bed_id
      @destination_bed
    end
  end
end
