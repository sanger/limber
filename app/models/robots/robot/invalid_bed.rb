
module Robots
  class Robot::InvalidBed
    def initialize(barcode)
      @barcode = barcode
    end

    def load(_); end

    def formatted_message
      match = /[0-9]{12,13}/.match(@barcode)
      match ? "Bed with barcode #{@barcode} is not expected to contain a tracked plate." :
              "#{@barcode} does not appear to be a valid bed barcode."
    end

    def valid?
      false
    end
  end
end
