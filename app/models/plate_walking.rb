# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012 Genome Research Ltd.
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

      def eql?(location)
        to_s.eql?(location.to_s)
      end

      def to_s
        "#{row}#{column}"
      end
    end

    def initialize(plate, wells)
      well_pair = Hash[plate.locations_in_rows.map { |l| [Location.new(l), nil] }]
      wells.each { |well| well_pair[Location.new(well.location)] = well }
      @rows = well_pair.group_by { |l, _| l.row }.map { |l, w| [l, w.map(&:last)] }
    end

    delegate :each, to: :@rows
  end
end
