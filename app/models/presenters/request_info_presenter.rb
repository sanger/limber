# frozen_string_literal: true

# Presents information about requests associated with a given labware item.
#
# This presenter provides methods to summarize and group active requests for a labware,
# such as grouping by request type and state, and generating human-readable summaries.
class Presenters::RequestInfoPresenter
  attr_reader :labware

  # redirect presenter methods to the labware
  delegate :uuid, to: :labware

  # Initializes the presenter with the given labware.
  #
  # @param labware [Labware] The labware item to present.
  def initialize(labware)
    @labware = labware
  end

  delegate :active_requests, to: :@labware

  # Groups active requests by the specified attributes and returns a hash with the count for each group.
  #
  # Each group key is an array of attribute values (e.g. [request_type.name, request.state]).
  # If the attribute is not found on the request, it is looked up on the request's request_type.
  #
  # @param by [Array<Symbol>] The list of attributes to group by. Defaults to [:name, :state].
  # @return [Hash<Array, Integer>] A hash where the key is an array of attribute values and
  #    the value is the count of requests in that group.
  #
  # @example
  #   grouped_active_requests
  #   # => {["LCM Triomics WGS", "passed"] => 24, ["LCM Triomics EMSeq", "failed"] => 24}
  def grouped_active_requests(by: %i[name state])
    active_requests.group_by do |request|
      by.map do |attr|
        request.send(attr)
      rescue NoMethodError
        request.request_type.send(attr)
      end
    end
      .transform_values(&:size)
  end
end
