# frozen_string_literal: true

# A pool is a set of samples due to be processed together
# with similar parameters. Usually they will end up eventually
# being combined together in a 'pool although increasingly this
# definition is being stretched. Pool information is supplied as
# part of the plate json.
# The Pools class takes the pools hash, and provides a convenient
# interface for accessing the information
class Limber::Plate::Pools
  # The total number of pools listed on the plate. In most
  # cases indicated the number of tubes which will be created
  attr_reader :number_of_pools
  # An array of the uuids of the submissions associated with the plate
  attr_reader :submissions
  # A number of attributes should be consistent across the plate.
  # The example pool provides a source of this information
  # We should possibly move away from this assumption
  attr_reader :example_pool

  delegate :library_type_name, :insert_size, :primer_panel, to: :example_pool
  #
  # Create a new Pools from the pool information.
  #
  # @param [Hash] pools_hash  As provided by the pools hash in the plate json
  #
  def initialize(pools_hash)
    pools_hash ||= {}
    @number_of_pools = pools_hash.length
    @submissions = pools_hash.keys
    @pools = pools_hash.map { |uuid, pool| Limber::Plate::Pool.new(uuid, pool) }
    @example_pool = @pools.first || Limber::Plate::Pool.new(nil, {})
  end

  # Plates are ready for pooling once we're in to the multiplex phase of the pipeline
  # This is indicated by the request type on the pools, and indicates that the plates
  # have been charged and passed.
  # We need at least one pool for automatic pooling to function.
  def ready_for_automatic_pooling?
    @pools.present? && ready_for_custom_pooling?
  end

  # Custom pooling is a little more flexible. Than automatic pooling, in that it DOESNT
  # require downstream submission and is completely happy with empty pools
  def ready_for_custom_pooling?
    @pools.empty? || @pools.any?(&:ready_for_custom_pooling?)
  end
end
