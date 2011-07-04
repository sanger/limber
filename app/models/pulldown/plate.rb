class Pulldown::Plate < Sequencescape::Plate
  # Returns a plate instance that has been coerced into the appropriate class if necessary.  Typically
  # this is only done at the end of the pipelines when extra functionality is required when dealing
  # with the transfers into tubes.
  def coerce
    return self unless passed? and is_a_final_pooling_plate?
    coerce_to(Pulldown::PooledPlate)
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
end
