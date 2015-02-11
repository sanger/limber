#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.
class IlluminaB::Plate < Sequencescape::Plate
  # Returns a plate instance that has been coerced into the appropriate class if necessary.  Typically
  # this is only done at the end of the pipelines when extra functionality is required when dealing
  # with the transfers into tubes.
  def coerce
    return self unless tubes_created? and is_a_final_pooling_plate?
    coerce_to(IlluminaB::FinalPoolPlate)
  end

  FINAL_POOLING_PLATE_PURPOSES = [
    'ILB_STD_PCRXP',
    'ILB_STD_PCRRXP',
    'Lib PCR-XP',
    'Lib PCRR-XP',
    'ISCH lib pool',
    'ISCH cap lib pool'
  ]

  TUBES_ON_PASS = [

    'ISCH cap lib pool'
  ]

  def is_a_final_pooling_plate?
    FINAL_POOLING_PLATE_PURPOSES.include?(plate_purpose.name)
  end
  private :is_a_final_pooling_plate?

  def tubes_created?
    qc_complete? || (passed? && tubes_on_pass?)
  end

  def tubes_on_pass?
    TUBES_ON_PASS.include?(plate_purpose.name)
  end

  def library_type_name
    uuid = pools.keys.first
    uuid.nil? ? 'Unknown' : pools[uuid]['library_type']['name']
  end

  def number_of_pools
    pools.keys.count
  end

  def role
    label.prefix
  end

  def shearing_size
    uuid = pools.keys.first
    uuid.nil? ? 'Unknown' : pools[uuid]["insert_size"].to_a.join(' ')
  end

end
