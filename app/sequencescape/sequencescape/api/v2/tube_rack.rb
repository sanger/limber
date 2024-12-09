# frozen_string_literal: true

require_dependency 'well_helpers'

# Tube racks can be barcoded, and contain racked tubes at defined locations.
class Sequencescape::Api::V2::TubeRack < Sequencescape::Api::V2::Base
  include WellHelpers::Extensions # obviously tube racks do not have wells, refactor the helper?
  include Sequencescape::Api::V2::Shared::HasRequests
  include Sequencescape::Api::V2::Shared::HasPurpose
  include Sequencescape::Api::V2::Shared::HasBarcode
  include Sequencescape::Api::V2::Shared::HasPolyMetadata

  self.tube_rack = true

  STATES_TO_FILTER_OUT = %w[cancelled failed].freeze
  STATE_EMPTY = 'empty'
  STATE_MIXED = 'mixed'

  # This is needed in order for the URL helpers to work correctly
  def to_param
    uuid
  end

  #
  # Override the model used in form/URL helpers
  # to allow us to treat old and new api the same
  #
  # @return [ActiveModel::Name] The resource behaves like a Limber::TubeRack
  #
  def model_name
    ::ActiveModel::Name.new(Limber::TubeRack, false)
  end

  has_many :racked_tubes, class_name: 'Sequencescape::Api::V2::RackedTube'
  has_many :tubes, through: :racked_tubes, class_name: 'Sequencescape::Api::V2::Tube'

  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset'

  has_many :state_changes

  property :name
  property :size
  property :number_or_rows
  property :number_of_columns

  property :created_at, type: :time
  property :updated_at, type: :time

  def stock_plate
    nil
  end

  # This method determines the state of the tube rack based on the states of the racked tubes.
  # It returns a single state if all racked tubes have the same state.
  # If there are multiple states, it filters out first 'cancelled' and then 'failed' states and
  # returns the remaining state if only one remains.
  # If there are still multiple states after filtering, it returns 'mixed'.
  # i.e. if all tubes are pending, the state will be 'pending'
  # i.e. if all tubes are failed, the state will be 'failed'
  # i.e. if we have a mix of 'cancelled' and 'failed' tubes, the state will be 'failed' as we filter out
  # the cancelled tubes first
  # i.e. if we have a mix of cancelled, failed and pending tubes, the state will be 'pending'
  # i.e. if we have a mix of cancelled, failed, pending and passed tubes, the state will be 'mixed'
  # i.e. if the tube rack is empty, the state will be 'empty'
  #
  # @return [String] the state of the tube rack
  def state
    # check if rack is empty
    return STATE_EMPTY if racked_tubes.empty?

    # fetch states from all tubes in the rack and see if we have a single state
    states = racked_tubes.map { |racked_tube| racked_tube.tube.state }.uniq
    return states.first if states.one?

    # we have a mix of states, filter out cancelled tubes first, and then if we still have
    # a mix, filter out the failed tubes and see if we have a single state after that
    STATES_TO_FILTER_OUT.each do |filter|
      states.delete(filter)
      return states.first if states.one?
    end

    # if we still have a mixed state, we display it as such
    STATE_MIXED
  end

  private

  # This method iterates over all racked tubes in the tube rack and retrieves the
  # aliquots for each associated tube. It flattens the resulting arrays into a single
  # array and removes any nil values.
  # Used to determine the active requests for the tube rack. See HasRequests for more details.
  #
  # @return [Array<Aliquot>] An array of aliquots for the tubes in the rack.
  #
  # Example:
  #   aliquots = tube_rack.aliquots
  #   # => [<Aliquot id: 1, ...>, <Aliquot id: 2, ...>, ...]
  #
  def aliquots
    racked_tubes.flat_map { |racked_tube| racked_tube.tube.aliquots }&.compact
  end

  # This method iterates over all racked tubes in the tube rack and retrieves the
  # requests_as_source for each associated tube. It flattens the resulting
  # arrays into a single array and removes any nil values.
  # Used to determine the active requests for the tube rack. See HasRequests for more details.
  #
  # @return [Array<Request>] An array of requests_as_source for the tubes in the rack.
  #
  # Example:
  #   requests = tube_rack.requests_as_source_for_tubes
  #   # => [<Request id: 1, ...>, <Request id: 2, ...>, ...]
  #
  def requests_as_source
    racked_tubes.flat_map { |racked_tube| racked_tube.tube.requests_as_source }&.compact
  end
end
