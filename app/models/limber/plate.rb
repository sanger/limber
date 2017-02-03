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

  def well_to_tube_transfers
    @transfers ||= transfers_to_tubes.first.transfers
  end

  # We know that if there are any transfers with this plate as a source then they are into
  # tubes.
  def transfers_to_tubes?
    transfers_to_tubes.present?
  end

  # Returns the tubes that an instance of this plate has been transferred into.
  # This ensures that tubes are sorted in column major order
  def tubes
    return [] unless transfers_to_tubes?
    WellHelpers.column_order.map(&well_to_tube_transfers.method(:[])).compact.uniq
  end

  def tubes_and_sources
    return [] unless transfers_to_tubes?
    WellHelpers.column_order.map do |l|
      [l, well_to_tube_transfers[l]]
    end.group_by do |_, t|
      t && t.uuid
    end.reject do |uuid, _|
      uuid.nil?
    end.map do |_, well_tube_pairs|
      [well_tube_pairs.first.last, well_tube_pairs.map(&:first)]
    end
  end
end
