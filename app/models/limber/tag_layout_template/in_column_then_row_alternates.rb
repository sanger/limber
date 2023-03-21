# frozen_string_literal: true


# TODO comments
module Limber::TagLayoutTemplate::InColumnThenRowAlternates
  def group_wells_of_plate(plate)
    group_wells(plate) do |well_location_pool_pair|
      WellHelpers.column_order(plate.size).map { |row_column| well_location_pool_pair.call(row_column) }
    end
  end
  private :group_wells_of_plate

  def primary_index(row, column, scale, height, _width)
    tag_col = (column / scale)
    tag_row = (row / scale)
    tag_row + (height / scale * tag_col)
  end
end
