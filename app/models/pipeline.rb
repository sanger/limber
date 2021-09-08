# frozen_string_literal: true

# A Pipeline is a series of steps that may be performed to complete a request.
# Steps are represented as a series of parent-child relationships reflecting
# transfer from one labware type to another.
# While Limber allows users to deviate from a pipeline, the series of steps
# specified defines the suggested 'green' route.
class Pipeline
  include ActiveModel::Model

  # The name of the pipeline. Currently used internally, but may get exposed to users
  # in future.
  # @return [String] Name of the pipeline
  attr_accessor :name

  # The filters that will be used to identify whether a plate belongs to a particular pipeline
  # Keys should be attributes on request (eg. library_type) whereas values are either an array
  # of acceptable values, or a single acceptable value
  # @example
  #   pipeline.filters = { 'request_type_key' => 'library_request', 'library_type' => ['Stndard', 'Other'] }
  # @return [Hash] Filter options
  attr_reader :filters

  # The plate types(s) for which to suggest library passing for this particular pipeline
  # @return [Array, String]
  attr_accessor :library_pass

  # Hash of parent => child relationships. Indicates the steps which form part of this pipeline.
  # Be aware, that this will restrict you to one child type per parent, per pipeline.
  # Currently branching pipelines can be represented as two separate pipelines.
  # @return [Hash<String>] Hash of parent (key) and child (value) relationships
  attr_accessor :relationships

  # Plate purpose that could be use as an alternative workline identifier in the barcode top right field
  # when there are more than one ancestors that are Stock plates
  attr_accessor :alternative_workline_identifier

  # Checks if a piece of labware meets the filter criteria for a pipeline
  # @return [Boolean] returns true if labware meets the filter criteria
  def active_for?(labware)
    # temp hack
    # TODO: allow for option where there are no requests - e.g. if pipeline config has no 'filters', return true
    true
    # labware.active_requests.any? do |request|
    #   # For each attribute (eg. library_type) check that the matching property
    #   # on request is included in the list of permitted values.
    #   filters.all? do |request_attribute, permitted_values| # state, "passed"
    #     permitted_values.include? request.public_send(request_attribute)
    #   end
    # end
  end

  def filters=(filters)
    # Convert any singlular values to an array to provide a consistent interface
    @filters = filters.transform_values { |value| Array(value) }
  end

  # Returns the suggested child purpose for the provided parent
  # @return [String] The purpose name
  def child_for(purpose)
    relationships[purpose]
  end

  #
  # Returns true if the pipeline suggest library passing for the given purpose
  # @param purpose [String] The name of the purpose being queried
  #
  # @return [Boolean] True if it should suggest passing
  def library_pass?(purpose)
    Array(library_pass).include?(purpose)
  end
end
