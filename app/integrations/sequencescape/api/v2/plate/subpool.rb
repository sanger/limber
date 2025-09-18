# frozen_string_literal: true

# A pool is a set of samples due to be processed together
# with similar parameters. Usually they will end up eventually
# being combined together in a 'pool although increasingly this
# definition is being stretched. Pool information is supplied as
# part of the plate json.
# The Pool class takes an individual pool, and provides a convenient interface
class Sequencescape::Api::V2::Plate::Subpool
  WellRequest = Struct.new(:well, :request)

  # The group identifier is formed by either the pre-capture group
  # or the order-id
  attr_reader :group_identifier

  def initialize
    @well_requests = []
  end

  def well_count
    @well_requests.length
  end

  def well_locations
    @well_requests.map { |well_request| well_request.well.location }
  end

  delegate :fragment_size, to: :primary_request

  delegate :library_type, to: :primary_request

  def add_well_request(well, request)
    self.group_identifier = request.group_identifier
    @well_requests << WellRequest.new(well, request)
  end

  def group_identifier=(group_identifier)
    @group_identifier ||= group_identifier

    # In theory this exception should never be hit, as we should only be
    # doing this if compatible? returns true.
    raise StandardError, 'Incorrect pool assembly' if @group_identifier != group_identifier
  end

  #
  # Returns true if a well/request may form part of a sub-pool
  # Subpools are currently formed by pre-capture group, or, if not specified
  # order id.
  # Future changes should ensure the following:
  # 1) That any of the request options displayed here are consistent across the group
  # 2) That each well only appears once in each subpool
  # @param well [type] [description]
  # @param request [type] [description]
  #
  # @return [type] [description]
  def compatible?(_well, request)
    group_identifier == request.group_identifier
  end

  private

  # Since all requests SHOULD have the same metadata, we pick the first
  def primary_request
    @well_requests.first.request
  end
end
