class Pulldown::Plate < Sequencescape::Plate
  # Returns a plate instance that has been coerced into the appropriate class if necessary.  Typically
  # this is only done at the end of the pipelines when extra functionality is required when dealing
  # with the transfers into tubes.
  def coerce
    return self unless passed? and is_a_final_pooling_plate?
    coerce_to(Pulldown::PooledPlate)
  end

  def after_load
    wells_to_pools = {}
    self.pools.each do |pool_id,wells|
      wells.each { |well| wells_to_pools[well] = pool_id }
    end

    self.wells.each do |well|
      pool_id = wells_to_pools[well.location]
      well.singleton_class.send(:define_method, :pool) { pool_id }
    end
  end

  FINAL_POOLING_PLATE_PURPOSES = [
    'WGS pooled amplified library plate',
    'SC pooled captured library plate',

    # ISC does two stages of pooling
    'ISC pooled amplified library plate',
    'ISC pooled captured library plate'
  ]

  def is_a_final_pooling_plate?
    FINAL_POOLING_PLATE_PURPOSES.include?(plate_purpose.name)
  end
  private :is_a_final_pooling_plate?

  def ordered_pools
    x = Hash.new { |h,k| h[k] = [] }
    self.wells.each { |well| x[pool_for_well(well)] << well.location }
    x.values
  end

  def pool_for_well(well)
    self.pools.detect { |pool_id, wells| wells.include?(well.location) }
  end
end
