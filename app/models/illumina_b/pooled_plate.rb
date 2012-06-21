class IlluminaB::PooledPlate < Sequencescape::Plate
  # We need to specialise the transfers where this plate is a source so that it handles
  # the correct types
  class Transfer < ::Sequencescape::Transfer
    belongs_to :source, :class_name => 'PooledPlate', :disposition => :inline
    attribute_reader :transfers

    def transfers_with_tube_mapping=(transfers)
      send(
        :transfers_without_tube_mapping=, Hash[
          transfers.map do |well, tube_json|
            [ well, ::IlluminaB::MultiplexedLibraryTube.new(api, tube_json, false) ]
          end
        ]
      )
    end
    alias_method_chain(:transfers=, :tube_mapping)
  end

  has_many :transfers_to_tubes, :class_name => 'PooledPlate::Transfer'

  def well_to_tube_transfers
    transfers_to_tubes.first.transfers
  end

  # We know that if there are any transfers with this plate as a source then they are into
  # tubes.
  def has_transfers_to_tubes?
    not well_to_tube_transfers.empty?
  end

  # Well locations ordered by rows.
  WELLS_IN_ROW_MAJOR_ORDER = ('A'..'H').inject([]) { |a,r| a.concat((1..12).map { |c| "#{r}#{c}" }) ; a }

  # Returns the tubes that an instance of this plate has been transferred into.
  def tubes
    return [] unless has_transfers_to_tubes?
    WELLS_IN_ROW_MAJOR_ORDER.map(&well_to_tube_transfers.method(:[])).compact.uniq
  end

  def tubes_and_sources
    return [] unless has_transfers_to_tubes?
    WELLS_IN_ROW_MAJOR_ORDER.map do |l|
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
