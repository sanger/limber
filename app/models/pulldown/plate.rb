class Pulldown::Plate < Sequencescape::Plate
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
    'ISC cap lib pool',

    'ISCH lib pool',
    'ISCH cap lib pool'
  ]

  def is_a_final_pooling_plate?
    FINAL_POOLING_PLATE_PURPOSES.include?(plate_purpose.name)
  end
  private :is_a_final_pooling_plate?
end
