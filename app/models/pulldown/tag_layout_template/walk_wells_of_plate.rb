module Pulldown::TagLayoutTemplate::WalkWellsOfPlate
  def generate_tag_layout(plate, tagged_wells)
    tags, group = tag_ids, []
    groups = group_wells_of_plate(plate).each { |g| group.concat(g) }
    pools  = groups.map { |pool| pool.map { |w| w.try(:[], 1) } }.flatten.compact.uniq

    group.each_with_index do |(well, pool_id, _), index|
      throw :unacceptable_tag_layout if tags.size <= index
      tagged_wells[well] = [ pools.index(pool_id)+1, tags[index] ] unless well.nil?
    end
  end
end
