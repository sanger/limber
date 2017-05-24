# frozen_string_literal: true

class Limber::Plate < Sequencescape::Plate
  # Customize the has_many association to use out custom class.
  has_many :transfers_to_tubes, class_name: 'Limber::TubeTransfer'

  def library_type_name
    uuid = pools.keys.first
    uuid.nil? ? 'Unknown' : pools[uuid]['library_type']['name']
  end

  def number_of_pools
    pools.keys.count
  end

  def pcr_cycles
    @pcr_cycles ||= pools.values.map { |pool| pool.fetch('pcr_cycles', 'Not specified') }.uniq
  end

  def role
    label.prefix
  end

  def shearing_size
    uuid = pools.keys.first
    uuid.nil? ? 'Unknown' : pools[uuid]['insert_size'].to_a.join(' ')
  end

  def purpose
    plate_purpose
  end

  # We know that if there are any transfers with this plate as a source then they are into
  # tubes.
  def transfers_to_tubes?
    transfers_to_tubes.present?
  end

  def tubes_and_sources
    return [] unless transfers_to_tubes?
    tube_hash = Hash.new { |h, i| h[i] = [] }
    # Build a list of all source wells for a given tube
    well_to_tube_transfers.each do |well, tube|
      tube_hash[tube] << well
    end
    # Sort the source well list in column order
    tube_hash.transform_values! do |well_list|
      well_list.sort_by { |well_name| WellHelpers.index_of(well_name) }
    end
    # Sort the tubes in column order based on their first well
    tube_hash.sort_by { |_tube, well_list| WellHelpers.index_of(well_list.first) }
  end

  private

  def well_to_tube_transfers
    @transfers ||= transfers_to_tubes.each_with_object([]) do |transfer, all_transfers|
      all_transfers.concat(transfer.transfers.to_a)
    end
  end
end
