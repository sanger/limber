# frozen_string_literal: true

# A Pipeline is a series of steps that may be performed to complete a request.
# Steps are represented as a series of parent-child relationships reflecting
# transfer from one labware type to another.
# While Limber allows users to deviate from a pipeline, the series of steps
# specified defines the suggested 'green' route.
class Pipeline
  include ActiveModel::Model

  # The group the pipeline belongs to
  attr_writer :pipeline_group

  # The name of the pipeline. Currently used internally, but may get exposed to users
  # in future.
  # @return [String] Name of the pipeline
  attr_accessor :name

  def pipeline_group
    # When no group is provided, default pipeline group to the pipeline name
    @pipeline_group ||= name
  end

  # The filters that will be used to identify whether a plate belongs to a particular pipeline
  # Keys should be attributes on request (eg. library_type) whereas values are either an array
  # of acceptable values, or a single acceptable value
  # @example
  #   pipeline.filters = { 'request_type' => 'library_request', 'library_type' => ['Standard', 'Other'] }
  # @return [Hash] Filter options
  def filters
    @filters || {}
  end

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

  # Checks if the given labware meets the purpose and filter criteria for this pipeline.
  # If the labware's purpose is in the pipeline relationships, it will return true. If there are no
  # filter criteria, the pipeline could be active for any labware, and will return true if the
  # purpose is in the relationships. Otherwise, it will check if any of the active requests on the
  # labware meet the filter criteria, returning true if any do.
  #
  # @param labware [Sequencescape::Api::V2::Plate, Sequencescape::Api::V2::Tube] The labware to check
  # @return [Boolean] Returns true if the labware meets the criteria, false otherwise
  def active_for?(labware)
    return false unless purpose_in_relationships?(labware.purpose)
    return true if filters.blank?

    labware.active_requests.any? do |request|
      # For each attribute (eg. library_type) check that the matching property
      # on request is included in the list of permitted values.
      filters.all? do |request_attribute, permitted_values|
        permitted_values.include? request.public_send(request_attribute)
      end
    end
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

  # Checks if a given purpose is present in the relationships of this pipeline.
  #
  # @param purpose [String] The purpose to look for.
  #
  # @return [Boolean] Returns true if the purpose is present in this pipeline, false otherwise.
  def purpose_in_relationships?(purpose)
    (relationships.keys + relationships.values).include?(purpose.name)
  end
end
