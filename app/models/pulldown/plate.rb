class Pulldown::Plate < Sequencescape::Plate
  # Returns a plate instance that has been coerced into the appropriate class if necessary.  Typically
  # this is only done at the end of the pipelines when extra functionality is required when dealing
  # with the transfers into tubes.
  def coerce
    return self unless passed? and is_a_final_pooling_plate?
    coerce_to(Pulldown::PooledPlate)
  end

  def passed?
    state == 'passed'
  end
  private :passed?

  def is_a_final_pooling_plate?
    plate_purpose.name == 'WGS pooled amplified library plate'
  end
  private :is_a_final_pooling_plate?
end
