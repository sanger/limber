# frozen_string_literal: true

module TubeRackWalking # rubocop:todo Style/Documentation
  def tubes_by_row
    Walker.new(labware)
  end

  class Walker # rubocop:todo Style/Documentation
    def initialize(rack)
      indexed_tubes =
        rack.racked_tubes.each_with_object({}) { |racked_tube, store| store[racked_tube.coordinate] = racked_tube.tube }
      @rows = rack.rows_range.index_with { |row| rack.columns_range.map { |column| indexed_tubes["#{row}#{column}"] } }
    end

    delegate :each, to: :@rows
  end
end
