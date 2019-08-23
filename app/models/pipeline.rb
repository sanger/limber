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
  # @return [Hash] Filter options
  attr_accessor :filters

  # The plate types(s) for which to suggest library passing for this particular pipeline
  # @return [Array, String]
  attr_accessor :library_pass

  # Hash of parent => child relationships. Indicates the steps which form part of this pipeline.
  # Be aware, that this will restrict you to one child type per parent, per pipeline.
  # Currently branching pipelines can be represented as two separate pipelines.
  # @return [Hash<String>] Hash of parent (key) and child (value) relationships
  attr_accessor :relationships

  # Checks if a piece of labware meets the filter criteria for a pipeline
  # @return [Boolean] returns true if labware meets the filter criteria
  def active_for?(labware)
    labware.active_requests.any? do |request|
      (filters['request_type_keys'].blank? || filters['request_type_keys'].include?(request.request_type_key)) &&
        (filters['library_type_names'].blank? || filters['library_type_names'].include?(request.library_type))
    end
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
