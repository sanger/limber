##
# Helper methods to assist with show_pooled_alternative.erb
module Presenters::AlternativePooling

  def pool_destination_location(location)
    transfer_hash[location]
  end

  def sorted_pools
    @sorted_pools = transfer_hash.values.uniq.sort_by do |destination|
      destination_by_column(destination)
    end
  end

  def pool_number(source_location)
    sorted_pools.index(pool_destination_location(source_location))+1
  end

  def pool(location)
    pooled_to = pool_destination_location(location)
    pool_hash[pooled_to]
  end

  def num_rows(size)
    {
      96 => [ 12, 8 ],
      384 => [ 24, 16 ]
    }[size][1]
  end

  def destination_by_column(location)
    column, row_alpha = split_location(location)
    row_numeric = (row_alpha.ord - "A".ord) + 1
    row_numeric + (num_rows(labware.size) * (column - 1))
  end

  def location_of_pool_destination_from(location)
    destination_by_column(pool_destination_location(location))
  end

  def last_in_pool?(source_location)
    pool(source_location).last == source_location
  end

  def bait_library_for(location)
    well_baits[location]
  end

  private

  def pool_hash
    @pool_hash ||= Hash.new do |hash,destination|
      hash[destination] = source_wells_for(destination).sort_by {|source| destination_by_column(source)}
    end
  end

  def transfer_hash
    labware.creation_transfer.transfers
  end

  def source_wells_for(destination_well)
    transfer_hash.select {|source,destination| destination == destination_well}.keys
  end

  def well_baits
    @well_baits ||= Hash[labware.pools.values.map {|pool| [pool['wells'].first,pool['bait_library']['name']]}]
  end
end
