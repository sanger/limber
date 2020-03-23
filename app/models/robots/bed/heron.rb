# frozen_string_literal: true

module Robots::Bed
  class Heron < Robots::Bed::Base
    validate :validate_barcode_suffix    
    
    attr_accessor :plate_barcode_suffix, :expected_plate_barcode_suffix

    def validate_barcode_suffix
        return unless plate_barcode_suffix && expected_plate_barcode_suffix

        unless plate_barcode_suffix == expected_plate_barcode_suffix
          error("Expected plate barcode to end in the following suffix: #{expected_plate_barcode_suffix}")
        end
    end

    # private

  end
end
