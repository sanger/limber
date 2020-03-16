# frozen_string_literal: true

# A pool is a set of samples forming part of the same submission,
# usually to be pooled together.
# The Pool class takes an individual pool, and provides a convenient interface
class Sequencescape::Api::V2::Plate::Pool
  # The UUID of the submission associated with the pool
  attr_reader :submission_id, :subpools, :pool_index

  alias id submission_id

  # Create a new Pools from the pool information.
  #
  # @param [String] submission)id  The submission id of the pool
  def initialize(submission_id, pool_index)
    @submission_id = submission_id
    @subpools = []
    @pool_index = pool_index
    @submission = Sequencescape::Api::V2::Submission.where(id: submission_id)
  end

  def add_well_request(well, request)
    compatible_subpool(request).add_well_request(well, request)
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

  def number_of_lanes
    @submission.first.number_of_lanes
  end

  # def bait_library_name
  #   @submission.first.bait_library_name
  # end

  def subpool_of_well(well)
    # Rails.logger.debug("subpool_of_well()")
    # Rails.logger.debug(well.id)
    @subpools.each do |subpool|
      # Rails.logger.debug(subpool.well_requests)
      return subpool if subpool.well_requests.detect do |well_request|
        # Rails.logger.debug(well_request.well == well)
        well_request.well == well
      end
    end
  end

  private

  def compatible_subpool(request)
    @subpools.detect { |sp| sp.compatible?(request) } || new_subpool
  end

  def new_subpool
    Sequencescape::Api::V2::Plate::Subpool.new(@subpools.length + 1).tap do |subpool|
      @subpools << subpool
    end
  end
end
