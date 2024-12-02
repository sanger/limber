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
  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset'

  property :name
  property :size
  property :number_or_rows
  property :number_of_columns

  property :created_at, type: :time
  property :updated_at, type: :time

  def stock_plate
    nil
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
