# frozen_string_literal: true

module Limber::TagLayoutTemplate::InRows
  def group_wells_of_plate(plate)
    group_wells(plate) do |well_location_pool_pair|
      WellHelpers.row_order(plate.size).map do |row_column|
        well_location_pool_pair.call(row_column)
      end
    end
  end
end
