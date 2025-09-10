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

  DEFAULT_TUBE_RACK_INCLUDES = [:purpose, 'racked_tubes', 'racked_tubes.tube'].freeze
  STATES_TO_FILTER_OUT = %w[cancelled failed].freeze
  STATE_EMPTY = 'empty'
  STATE_MIXED = 'mixed'

  # Overrides the Rails method to return the UUID of the labware for use in URL generation.
  #
  # @return [String] The UUID of the labware instance.
  def to_param
    # Currently use the uuid as our main identifier, might switch to human barcode soon
    uuid
  end

  # Override the model used in form/URL helpers such as polymorphic_path
  # to allow us to return an application-native model instead of the API model.
  #
  # @return [ActiveModel::Name] The resource behaves like a TubeRack
  #
  def model_name
    ::ActiveModel::Name.new(TubeRack)
  end

  has_many :racked_tubes, class_name: 'Sequencescape::Api::V2::RackedTube'
  has_many :tubes, through: :racked_tubes, class_name: 'Sequencescape::Api::V2::Tube'
  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset'

  has_one :custom_metadatum_collection, class_name: 'Sequencescape::Api::V2::CustomMetadatumCollection'

  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset'
  has_many :children, class_name: 'Sequencescape::Api::V2::Asset'

  has_many :state_changes

  property :name
  property :size
  property :number_or_rows
  property :number_of_columns

  property :created_at, type: :time
  property :updated_at, type: :time

  # makes use of the StringInquirer class returned by the state method to provide a more readable way to
  # check the state of the tube rack e.g. tube_rack.state.passed? instead of tube_rack.state == 'passed'
  delegate :pending?, :started?, :passed?, :failed?, :cancelled?, :mixed?, :empty?, to: :state

  def stock_plate
    nil
  end

  def self.find_by(options, includes: DEFAULT_TUBE_RACK_INCLUDES)
    Sequencescape::Api::V2::TubeRack.includes(*includes).find(**options).first
  end

  def self.find_all(options, includes: DEFAULT_TUBE_RACK_INCLUDES)
    Sequencescape::Api::V2::TubeRack.includes(*includes).where(**options).all
  end

  # This method sorts the racked tubes by their coordinate, taking into account both row and column parts.
  # Sorts by column first and then by row.
  #
  # NB. Assumption that the coordinate is in the format [A-Z][0-9]+ e.g. A1, B12, C3, etc.
  # Where the first character is the row and the remaining digits are the column.
  # Deals with both single digit coordinates (e.g. A1, C2, D12) and zero filled digit coordinates
  # e.g. A01, C02, D12 etc.
  # @return [Array<RackedTube>] An array of racked tubes sorted by their coordinate.
  def racked_tubes_in_columns
    @racked_tubes_in_columns ||=
      racked_tubes.sort_by { |racked_tube| [racked_tube.coordinate[1..].to_i, racked_tube.coordinate[0]] }
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
  # @return [StringInquirer] the state of the tube rack wrapped in a StringInquirer object
  # rubocop:disable Metrics/AbcSize
  def state
    # check if rack is empty
    return STATE_EMPTY.inquiry if racked_tubes.empty?

    # fetch states from all tubes in the rack and see if we have a single state
    states = racked_tubes.map { |racked_tube| racked_tube.tube.state }.uniq
    return states.first.inquiry if states.one?

    # we have a mix of states, filter out cancelled tubes first, and then if we still have
    # a mix, filter out the failed tubes and see if we have a single state after that
    STATES_TO_FILTER_OUT.each do |filter|
      states.delete(filter)
      return states.first.inquiry if states.one?
    end

    # if we still have a mixed state, we display it as such
    STATE_MIXED.inquiry
  end

  # rubocop:enable Metrics/AbcSize

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
