# frozen_string_literal: true

module PlateWalking
  def wells_by_row
    Walker.new(plate_to_walk, plate_to_walk.wells)
  end

  class Walker
    class Location
      def initialize(alphanumeric_location)
        (match = /^([A-Z])(\d+)$/.match(alphanumeric_location)) || raise(StandardError, "Invalid well location #{alphanumeric_location.inspect}")
        @row = match[1]
        @column = match[2].to_i
      end

      attr_reader :row, :column

      delegate :hash, to: :to_s

      def eql?(other)
        to_s.eql?(other.to_s)
      end

      def to_s
        "#{row}#{column}"
      end
    end

    def initialize(plate, wells)
      well_pair = plate.locations_in_rows.each_with_object({}) { |l, hash| hash[Location.new(l)] = nil }
      wells.each { |well| well_pair[Location.new(well.location)] = well }
      @rows = well_pair.group_by { |l, _| l.row }.map { |row_name, w| [row_name, w.map(&:last)] }
    end

    delegate :each, to: :@rows
  end
end
