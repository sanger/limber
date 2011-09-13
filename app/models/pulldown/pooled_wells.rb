module Pulldown::PooledWells
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
end
