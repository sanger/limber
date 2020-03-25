# frozen_string_literal: true

module Robots::Bed
  # Specific to Heron pipeline - see HeronRobot for detail
  class Heron < Robots::Bed::Base
    validate :validate_barcode_suffix

    attr_accessor :plate_barcode_suffix, :expected_plate_barcode_suffix

    def validate_barcode_suffix
      return unless barcodes.present? && expected_plate_barcode_suffix

      return if plate_barcode_suffix == expected_plate_barcode_suffix

      error("Expected plate barcode to end in the following suffix: #{expected_plate_barcode_suffix}")
    end
  end
end
