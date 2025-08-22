# frozen_string_literal: true

# A concern to encapsulate Rails routing proxy behaviour for labware models that use a Sequencescape API.
# See the route definitions in `config/routes.rb` for the `resources` to `controller` mapping.
module RoutingLabware
  extend ActiveSupport::Concern

  included { attr_reader :api, :id }

  # Initializes the model with an ID, which is used for routing.
  # @param api [Sequencescape::Api] DEPRECATED: The API v1 instance
  # @param id [UUID] The identifier of the labware to redirect to
  # @return [void]
  # @example
  #   plate = Plate.new(api, '123e4567-e89b-12d3-a456-426614174000')
  #   puts plate.to_param # Outputs: '123e4567-e89b-12d3-a456-426614174000'
  def initialize(api, id)
    @api = api
    @id = id
  end

  # Overrides the Rails method to return the UUID of the labware for use in URL generation.
  #
  # @return [String] The UUID of the labware instance.
  def to_param
    # Currently use the uuid as our main identifier, might switch to human barcode soon
    @id
  end

  def to_model
    self
  end

  # Returns the ActiveModel::Name instance for the current class.
  # This is used by Rails for routing and form helpers to determine the model name.
  # @return [ActiveModel::Name] The model name for the class
  def model_name
    ::ActiveModel::Name.new(self.class, nil)
  end

  # Indicates that the labware object is considered persisted.
  # This is required by Rails form and routing helpers to treat the object as saved in the database.
  # @return [Boolean] Always returns true
  def persisted?
    true
  end
end
