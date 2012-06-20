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

  has_many :source_transfers, :class_name => 'PooledPlate::Transfer'

  # We know that if there are any transfers with this plate as a source then they are into
  # tubes.
  def has_transfers_to_tubes?
    not source_transfers.empty?
  end

  # Well locations ordered by columns.
  WELLS_IN_COLUMN_MAJOR_ORDER = (1..12).inject([]) { |a,c| a.concat(('A'..'H').map { |r| "#{r}#{c}" }) ; a }

  # Returns the tubes that an instance of this plate has been transferred into.
  def tubes
    return [] unless has_transfers_to_tubes?
    transfers = source_transfers.first.transfers
    WELLS_IN_COLUMN_MAJOR_ORDER.map(&transfers.method(:[])).compact
  end

  def source_of(tube)
    self.source_transfers.first.transfers.key(tube)
  end

end
