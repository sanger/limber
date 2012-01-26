class Pulldown::Plate < Sequencescape::Plate
  include Pulldown::PooledWells

  # Returns a plate instance that has been coerced into the appropriate class if necessary.  Typically
  # this is only done at the end of the pipelines when extra functionality is required when dealing
  # with the transfers into tubes.
  def coerce
    return self unless passed? and is_a_final_pooling_plate?
    coerce_to(Pulldown::PooledPlate)
  end

  FINAL_POOLING_PLATE_PURPOSES = [
    'WGS lib pool',
    'SC cap lib pool',

    # ISC does two stages of pooling
    'ISC lib pool',
    'ISC cap lib pool'
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

  def rows
    case self.size
    when 96  then ('A'..'H')
    when 384 then ('A'..'P')
    else          raise RuntimeError, "Unknown plate size #{self.size}"
    end
  end

  def columns
    case self.size
    when 96  then (1..12)
    when 384 then (1..24)
    else          raise RuntimeError, "Unknown plate size #{self.size}"
    end
  end

  def locations_in_rows
    [].tap do |locations|
      self.rows.each do |row|
        self.columns.each do |column|
          locations << "#{row}#{column}"
        end
      end
    end
  end
end
