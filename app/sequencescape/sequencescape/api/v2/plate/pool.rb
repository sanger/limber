# frozen_string_literal: true

# A pool is a set of samples forming part of the same submission,
# usually to be pooled together.
# The Pool class takes an individual pool, and provides a convenient interface
class Sequencescape::Api::V2::Plate::Pool
  # The uuid of the submission associated with the pool
  attr_reader :submission_id, :subpools, :pool_index

  alias id submission_id

  #
  # Create a new Pools from the pool information.
  #
  # @param [String] submission)id  The submission id of the pool
  def initialize(submission_id, pool_index)
    @submission_id = submission_id
    @subpools = []
    @pool_index = pool_index
  end

  def lane_count
    @lane_count || '?'
  end

  def add_well_request(well, request)
    @lane_count ||= request.submission&.lanes_of_sequencing
    compatible_subpool(well, request).add_well_request(well, request)
  end

  # The total number of wells contributing to the pool
  # Note: If a well goes down two separate routes, then it will
  # be counted twice.
  def well_count
    subpools.sum(&:well_count)
  end

  def well_locations
    subpools.flat_map(&:well_locations)
  end

  private

  def compatible_subpool(well, request)
    @subpools.detect { |sp| sp.compatible?(well, request) } || new_subpool
  end

  def new_subpool
    Sequencescape::Api::V2::Plate::Subpool.new.tap { |subpool| @subpools << subpool }
  end
end
