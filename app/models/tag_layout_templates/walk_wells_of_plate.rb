# frozen_string_literal: true

module TagLayoutTemplates::WalkWellsOfPlate # rubocop:todo Style/Documentation
  def generate_tag_layout(plate)
    tagged_wells = {}
    tags = tag_ids
    groups = group_wells_of_plate(plate)
    pools = groups.filter_map { |w| w.try(:[], 1) }.uniq

    groups.each_with_index do |(well, pool_id, _well_empty), index|
      throw :unacceptable_tag_layout if tags.size <= index
      tagged_wells[well] = [pools.index(pool_id) + 1, tags[index]] unless well.nil?
    end

    tagged_wells
  end
end
