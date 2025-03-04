# frozen_string_literal: true

# The TubeRackWalking module provides functionality to iterate over tubes in a tube rack by row.
# It defines a method `tubes_by_row` that returns a Walker object, which can be used to iterate
# over the tubes in the rack in a row-wise manner.
#
# Example usage:
#   include TubeRackWalking
#   tubes_by_row.each do |row, tubes|
#     puts "Row #{row}: #{tubes.map(&:id).join(', ')}"
#   end
module TubeRackWalking
  def tubes_by_row
    Walker.new(labware)
  end

  # The Walker class is responsible for iterating over the tubes in a tube rack by row.
  # It initializes with a tube rack and creates a hash where each key is a row and the value
  # is an array of tubes in that row, ordered by their column coordinates.
  #
  # Example usage:
  #   walker = Walker.new(tube_rack)
  #   walker.each do |row, tubes|
  #     puts "Row #{row}: #{tubes.map(&:id).join(', ')}"
  #   end
  class Walker
    # Initializes a new Walker object with the given tube rack.
    # It creates a hash where each key is a row and the value is an array of tubes in that row,
    # ordered by their column coordinates.
    #
    # @param rack [TubeRack] the tube rack to iterate over
    def initialize(rack)
      indexed_tubes =
        rack.racked_tubes.each_with_object({}) { |racked_tube, store| store[racked_tube.coordinate] = racked_tube.tube }
      @rows = rack.rows_range.index_with { |row| rack.columns_range.map { |column| indexed_tubes["#{row}#{column}"] } }
    end

    # Delegates the each method to the @rows hash, allowing iteration over the rows and tubes.
    #
    # @yield [row, tubes] Yields each row and its corresponding array of tubes to the block.
    delegate :each, to: :@rows
  end
end
