# frozen_string_literal: true

# This presenter is used to show the pipeline context for a labware item.
# It shows the appropriate pipeline name, along with the path through the
# pipeline that that particular labware has come, and the potential child
# purposes that it could continue as.
class Presenters::PipelineInfoPresenter
  include Presenters::CreationBehaviour

  attr_reader :labware

  # redirect presenter methods to the labware
  delegate :uuid, to: :labware

  # Initializes the presenter with the given labware.
  #
  # @param labware [Labware] The labware item to present.
  def initialize(labware)
    @labware = labware
  end

  # Determine which pipeline group(s?) the labware is in.
  #
  # There are three different methods of linking labware to a pipeline:
  #
  # 1. By purpose            - the pipeline is determined by the labware's purpose as specified in the config
  # 2. By request (optional) - the pipeline is determined by the active requests on the labware
  # 3. By library (optional) - the pipeline is determined by the library type of the labware
  #
  # In some cases, an intersection of these three groups might be required to accurately determine
  # the pipeline and pipeline group, in others the parent purpose might be used to determine the pipeline.
  def pipeline_groups
    pipeline_groups = [
      pipeline_groups_by_purpose, # allows matching pipeline purposes with no active requests
      pipeline_groups_by_parent_purposes, # any matching pipeline MIGHT match the labware's parent purposes
      pipeline_groups_by_requests_and_libraries # any matching pipeline MIGHT match the active requests and library type
    ]

    # Remove nil values and empty arrays from the pipeline_groups array
    pipeline_groups.compact!
    pipeline_groups.reject!(&:empty?)

    # intersect the pipeline groups to find the common pipelines
    pipeline_groups = pipeline_groups.reduce { |acc, group| acc & group }

    # Return the remaining pipeline groups as a sorted array, or nil if none are found.
    pipeline_groups.sort if pipeline_groups&.any?
  end

  # Returns the pipeline group name if there is only one pipeline group, otherwise nil.
  def pipeline_group_name
    return pipeline_groups.first if pipeline_groups&.size == 1

    nil
  end

  # Returns a string of the pipeline group names, or 'No Pipelines Found' if none are found.
  def pipeline_group_names
    return join_up_to(3, pipeline_groups) if pipeline_groups&.any?

    'No Pipelines Found'
  end

  # Returns true if the labware purpose has any defined grandparent relationships, false otherwise.
  # return [Boolean] True if the labware has grandparent purposes
  def grandparent_purposes?
    return false if @labware.parents.empty?

    parent_labwares = find_all_labware_parents_with_purposes
    grandparent_labwares = find_all_labware_parents_with_purposes(labwares: parent_labwares)

    true unless grandparent_labwares.empty?
  end

  # Returns a comma-separated list of the purposes of the labware's parents.
  # If the labware has no parents, it returns an empty string.
  # @return [String] Comma-separated list of parent purposes.
  def parent_purposes
    parent_purpose_names = find_all_labware_parents_with_purposes.map { |parent| parent.purpose.name }.uniq.sort
    join_up_to(2, parent_purpose_names)
  end

  # Returns a comma-separated list of potential child purposes for the labware.
  # If the labware is the last in the pipeline, it returns an empty string.
  # @return [String] Comma-separated list of child purposes
  def child_purposes
    join_up_to(2, suggested_purposes.map(&:name).uniq.sort)
  end

  private

  def cache_key
    "pipeline_info_presenter/#{@labware.barcode}"
  end

  def join_up_to(max_listed, array, separator = ', ')
    return array.join(separator) if array.size <= max_listed

    "#{array[0..(max_listed - 1)].join(separator)}, ...(#{array.size - max_listed} more)"
  end

  def pipeline_groups_by_purpose
    Settings
      .pipelines
      .select_pipelines_with_purpose(Settings.pipelines.list, @labware.purpose)
      .map(&:pipeline_group)
      .uniq
  end

  def pipeline_groups_by_requests_and_libraries
    active_pipelines.map(&:pipeline_group).uniq
  end

  def find_all_labware_parents_with_purposes(labwares: nil)
    labwares ||= [@labware]
    fn_cache_key = "#{cache_key}/find_all_labware_parents_with_purposes/#{labwares.map(&:barcode).uniq.join}"
    Rails.cache.fetch(fn_cache_key, expires_in: 1.minute) { find_all_labware_parents_with_purposes_uncached(labwares) }
  end

  def find_all_labware_parents_with_purposes_uncached(labwares)
    parent_barcodes = labwares.flat_map(&:parents).compact.map(&:barcode).uniq
    return [] if parent_barcodes.empty?

    Sequencescape::Api::V2::Labware.find_all(
      { barcode: parent_barcodes },
      includes: %w[purpose parents parents.purpose]
    )
  end

  # On `LB Lib Pool Norm` tubes, it's hard to find the correct pipeline,
  # because the same purpose and request type is used in many pipelines.
  # This looks at the parent labware, as this is normally specific to the pipeline.
  # This approach could cause problems if the parent labware is in a different pipeline,
  # however, in this case it is normally in the same pipeline *group*.
  def pipeline_groups_by_parent_purposes
    find_all_labware_parents_with_purposes
      .map(&:purpose)
      .map do |parent_purpose|
        Settings.pipelines.select_pipelines_with_purpose(Settings.pipelines.list, parent_purpose).map(&:pipeline_group)
      end
      .reduce(:&)
  end
end
