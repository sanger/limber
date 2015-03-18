#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
module IlluminaB::TagLayoutTemplate::WalkWellsOfPlate
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
