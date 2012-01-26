module PlateWalking
  def wells_by_row
    Walker.new(plate_to_walk, plate_to_walk.wells)
  end

  class Walker
    class Location
      def initialize(alphanumeric_location)
        match = /^([A-Z])(\d+)$/.match(alphanumeric_location) or raise StandardError, "Invalid well location #{alphanumeric_location.inspect}"
        @row, @column = match[1], match[2].to_i
      end

      attr_reader :row, :column

      def hash
        to_s.hash
      end

      def eql?(location)
        to_s.eql?(location.to_s)
      end

      def to_s
        "#{row}#{column}"
      end
    end

    def initialize(plate, wells)
      well_pair = Hash[plate.locations_in_rows.map { |l| [ Location.new(l), nil ] }]
      wells.each { |well| well_pair[Location.new(well.location)] = well }
      @rows = well_pair.group_by { |l,_| l.row }.map { |l,w| [ l, w.map(&:last) ] }
    end

    delegate :each, :to => :@rows
  end
end
