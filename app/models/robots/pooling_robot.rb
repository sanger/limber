# frozen_string_literal: true

module Robots
  class PoolingRobot < Robot
    attr_writer :destination_bed

    def plate_includes
      [:purpose, { wells: :upstream_plates }]
    end

    def valid_relationships
      verified = {}
      if destination_bed.empty?
        # We don't even have a destination barcode
        verified[destination_bed_id] = false
        error(destination_bed, 'No destination plate barcode provided')
      elsif destination_bed.valid?
        # The destination bed is valid, so check its parents are correct
        destination_bed.each_parent do |bed_barcode, expected_barcode|
          verified[bed_barcode] = validate_parent(bed_barcode, expected_barcode)
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

    private

    def validate_parent(bed_barcode, expected_barcode)
      parent_bed = beds.fetch(bed_barcode)
      return true if expected_barcode =~ parent_bed.barcode

      error(parent_bed, "Expected to contain #{expected_barcode} not #{parent_bed.barcode}")
      false
    end
  end
end
