# frozen_string_literal: true

# A concern to encapsulate Rails routing proxy behaviour for labware models that use a Sequencescape API.
module RoutingLabware
  extend ActiveSupport::Concern

  included { attr_reader :id }

  # Initializes the model with an ID, which is used for routing.
  # @param id [UUID, Integer] The identifier of the labware to redirect to
  # @return [void]
  # @example
  #   plate = Plate.new('123e4567-e89b-12d3-a456-426614174000')
  #   puts plate.to_param # Outputs: '123e4567-e89b-12d3-a456-426614174000'
  def initialize(id)
    @id = id
  end

  def to_param
    @id
  end

  def to_model
    self
  end
end
