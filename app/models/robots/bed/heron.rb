# frozen_string_literal: true

module Robots::Bed
  class Heron < Robots::Bed::Base
    validate :validate_barcode_suffix    
    
    attr_accessor :plate_barcode_suffix

    def validate_barcode_suffix
        return unless plate_barcode_suffix

        valid_suffixes = ['PP1', 'PP2']
        unless valid_suffixes.include? plate_barcode_suffix
          error("Expected plate barcode to end in one of the valid suffixes: #{valid_suffixes}")
        end
    end

    # private

  end
end
