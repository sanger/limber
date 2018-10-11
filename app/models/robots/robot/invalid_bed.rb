# frozen_string_literal: true

module Robots
  class Robot::InvalidBed
    def initialize(barcode)
      @barcode = barcode
    end

    def load(_); end

    def formatted_message
      if valid_barcode?
        "Bed with barcode #{@barcode} is not expected to contain a tracked plate."
      else
        "#{@barcode} does not appear to be a valid bed barcode."
      end
    end

    def valid?
      false
    end

    private

    def valid_barcode?
      /[0-9]{12,13}/.match(@barcode)
    end
  end
end
