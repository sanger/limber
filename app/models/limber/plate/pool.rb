# frozen_string_literal: true

# A pool is a set of samples due to be processed together
# with similar parameters. Usually they will end up eventually
# being combined together in a 'pool although increasingly this
# definition is being stretched. Pool information is supplied as
# part of the plate json.
# The Pool class takes an individual pool, and provides a convenient interface
class Limber::Plate::Pool
  # The uuid of the submission associated with the pool
  attr_reader :submission_uuid
  #
  # Create a new Pools from the pool information.
  #
  # @param [String] submission_uuid  The submission uuid of the pool (the key in the pools hash)
  # @param [Hash] pool_hash  As provided by the values in the pools hash in the plate json
  #
  def initialize(submission_uuid, pool_hash)
    @submission_uuid = submission_uuid
    pool_hash ||= {}
    @pool_hash = pool_hash
  end

  def pcr_cycles
    @pool_hash.fetch('pcr_cycles', 'Not specified')
  end

  def library_type_name
    @pool_hash.dig('library_type', 'name') || 'Unknown'
  end

  def insert_size
    sizes = @pool_hash.fetch('insert_size', ['Unknown'])
    sizes.to_a.join(' ')
  end

  def primer_panel
    @primer_panel ||= Limber::Plate::PrimerPanel.new(@pool_hash['primer_panel'])
  end

  # Custom pooling is a little more flexible. Than automatic pooling, in that it DOESNT
  # require downstream submission and is completely happy with empty pools
  def ready_for_custom_pooling?
    @pool_hash.fetch('for_multiplexing', false)
  end
end
