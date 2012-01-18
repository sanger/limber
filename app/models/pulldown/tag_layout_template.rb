class Pulldown::TagLayoutTemplate < Sequencescape::TagLayoutTemplate
  # Performs the coercion of this instance so that it behaves appropriately given the direction
  # and walking algorithm information.
  def coerce
    extend("pulldown/tag_layout_template/in_#{self.direction}s".camelize.constantize)
    extend("pulldown/tag_layout_template/walk_#{self.walking_by.gsub(/\s+/, '_')}".camelize.constantize)
    self
  end

  # This returns an array of well location to pool pairs.  The 'walker' is responsible for actually doing the walking
  # of the wells that are acceptable, and it calls back with the location of the well being processed.
  def group_wells(plate, &walker)
    well_to_pool = {}
    plate.pools.each do |pool_id, wells|
      wells.each { |well| well_to_pool[well] = pool_id }
    end

    # We assume that if a well is unpooled then it is in the same pool as the previous pool.
    prior_pool = nil
    callback = lambda do |row, column|
      prior_pool = pool = (well_to_pool["#{row}#{column}"] || prior_pool) or next
      emptiness = well_to_pool["#{row}#{column}"].nil?
      [ "#{row}#{column}", pool, emptiness ]  # Triplet: [ A1, pool_id, emptiness ]
    end
    yield(callback)
  end
  private :group_wells

  def tag_ids
    tag_group.tags.keys.map!(&:to_i).sort
  end
  private :tag_ids
end
