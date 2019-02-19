# frozen_string_literal: true

module Limber::TagLayoutTemplate::InRows
  def group_wells_of_plate(plate)
    group_wells(plate) do |well_location_pool_pair|
      WellHelpers.row_order(plate.size).map do |row_column|
        well_location_pool_pair.call(row_column)
      end
    end
  end

  # Returns the tag index for the primary tag
  # That is the one laid out in rows with four copies of each
  def primary_index(row, column, scale, _height, width)
    tag_col = (column / scale)
    tag_row = (row / scale)
    tag_col + (width / scale * tag_row)
  end
end
