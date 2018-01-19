# frozen_string_literal: true

module Limber::TagLayoutTemplate::InInverseColumns
  def group_wells_of_plate(plate)
    group_wells(plate) do |well_location_pool_pair|
      WellHelpers.column_order(plate.size).reverse.map do |row_column|
        well_location_pool_pair.call(row_column)
      end
    end
  end
  private :group_wells_of_plate
end
