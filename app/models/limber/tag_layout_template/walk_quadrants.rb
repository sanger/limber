# frozen_string_literal: true

module Limber::TagLayoutTemplate::WalkQuadrants
  def generate_tag_layout(plate)
    tags = tag_ids
    groups = group_wells_of_plate(plate)
    pools  = groups.map { |w| w.try(:[], 1) }.compact.uniq
    groups.each_with_object({}) do |(well, pool_id, _well_empty), tagged_wells|
      next if well.nil?
      column, row = WellHelpers.well_coordinate(well)
      index = primary_index(row, column - 1, 2, plate.height)
      throw :unacceptable_tag_layout if tags.size <= index
      tagged_wells[well] = [pools.index(pool_id) + 1, tags[index]] unless well.nil?
    end
  end
end
