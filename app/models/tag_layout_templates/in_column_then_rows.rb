# frozen_string_literal: true

# Used in quadrant layouts
# Tags are arranged in quadrants in the case of some 384 well plates.
# Essentially a 96 well plate of tags is transferred onto the same target
# plate four times, such that each cluster of 4 wells contains the same tag.
# Ie. Tag 1 is in wells A1, B1, A2, B2
# In the case of column then row direction algorithms
# Four different tag 2s then get applied to each cluster. These tags are
# laid out in *ROW* order
# ie. A1 => 1, A2 => 2, B1 => 3, B2 => 4
#
module TagLayoutTemplates::InColumnThenRows
  # Rows determined the second tag layout, which we don't
  # worry about here.
  def group_wells_of_plate(plate)
    group_wells(plate) do |well_location_pool_pair|
      WellHelpers.column_order(plate.size).map { |row_column| well_location_pool_pair.call(row_column) }
    end
  end
  private :group_wells_of_plate

  # Returns the tag index for the primary (i7) tag
  # That is the one laid out in columns with four copies of each
  #
  # @param row [Integer] Zero indexed row co-ordinate of the well
  # @param column [Integer] Zero-indexed column co-ordinate of the well
  # @param scale [Integer] The number of times each tag is repeated in a given row/column.
  #                        eg. 2 for quad stamps.
  # @param height [Integer] The number of rows on a plate
  # @param _width [Integer] The number of columns on a plate (unused)
  #
  # @return [Integer] The index of the tag to use for the well
  def primary_index(row, column, scale, height, _width)
    tag_col = (column / scale)
    tag_row = (row / scale)
    tag_row + (height / scale * tag_col)
  end
end
