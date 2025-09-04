# frozen_string_literal: true

# A pool is a set of samples due to be processed together
# with similar parameters. Usually they will end up eventually
# being combined together in a 'pool although increasingly this
# definition is being stretched. Pool information is supplied as
# part of the plate json.
# The Pools class takes the pools hash, and provides a convenient
# interface for accessing the information
class Sequencescape::Api::V2::Plate::Pools
  # Pools is a bit of a wrapper for the pools array, so lets delegate missing
  # to that.
  delegate_missing_to :pools

  def self.pool_hash
    Hash.new do |hash, submission_id|
      hash[submission_id] = Sequencescape::Api::V2::Plate::Pool.new(submission_id, hash.length + 1)
    end
  end

  #
  # Create a new Pools from the pool information.
  #
  # @param [Hash] pools_hash  As provided by the pools hash in the plate json
  #
  def initialize(wells)
    @pools_hash =
      wells.each_with_object(self.class.pool_hash) do |well, pools_hash|
        well.active_requests.each { |request| pools_hash[request.submission_id].add_well_request(well, request) }
      end
  end

  # The total number of pools listed on the plate. In most
  # cases indicated the number of tubes which will be created
  def number_of_pools
    @pools_hash.length
  end

  def pcr_cycles
    @pcr_cycles ||= @pools.flat_map(&:pcr_cycles).uniq
  end

  # Plates are ready for pooling once we're in to the multiplex phase of the pipeline
  # This is indicated by the request type on the pools, and indicates that the plates
  # have been charged and passed.
  # We need at least one pool for automatic pooling to function.
  def ready_for_automatic_pooling?
    @pools_hash.present? && ready_for_custom_pooling?
  end

  # Custom pooling is a little more flexible. Than automatic pooling, in that it DOESNT
  # require downstream submission and is completely happy with empty pools
  def ready_for_custom_pooling?
    @pools_hash.empty? || @pools_hash.any?(&:ready_for_custom_pooling?)
  end

  def pools
    @pools_hash.values
  end

  def pool_index(submission_id)
    @pools_hash.fetch(submission_id, nil)&.pool_index
  end
end
