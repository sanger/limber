# frozen_string_literal: true

# A PipelineList contains all registered {Pipeline pipelines} and is typically
# populated from config/pipelines/*.yml by {ConfigLoader::PipelinesLoader} during
# initialization.
class PipelineList
  attr_reader :list

  delegate_missing_to :list

  def initialize(list = {})
    @list = list.map do |pipeline_name, pipeline_config|
      Pipeline.new(pipeline_config.merge(name: pipeline_name))
    end
  end

  # Returns an array of all pipelines that are 'active' for a particular piece of
  # labware. An 'active' pipeline is one where one or more active requests on the
  # plate meet the filter criteria.
  def active_pipelines_for(labware)
    @list.select { |pipeline| pipeline.active_for?(labware) }
  end

  # Builds a flat list of purposes in a sensible order from the relationships config
  # Allowing the config hash to be in any order
  # For example getting from this:
  #
  # {
  #   "LTHR Cherrypick" => [ "LTHR-384 RT-Q" ],
  #   "LTHR-384 RT-Q" => [ "LTHR-384 PCR 1", "LTHR-384 PCR 2" ],
  #   "LTHR-384 RT" => [ "LTHR-384 PCR 1", "LTHR-384 PCR 2" ],
  #   "LTHR-384 PCR 1" => [ "LTHR-384 Lib PCR 1" ],
  #   "LTHR-384 Lib PCR 1" => [ "LTHR-384 Lib PCR pool" ],
  #   "LTHR-384 PCR 2" => [ "LTHR-384 Lib PCR 2" ],
  #   "LTHR-384 Lib PCR 2" => [ "LTHR-384 Lib PCR pool" ]
  # }
  #
  # To this:
  #
  # ["LTHR Cherrypick", "LTHR-384 RT", "LTHR-384 RT-Q", "LTHR-384 PCR 1", "LTHR-384 PCR 2", "LTHR-384 Lib PCR 1", "LTHR-384 Lib PCR 2", "LTHR-384 Lib PCR pool"]
  def combine_and_order_pipelines(pipeline_names)
    pipeline_configs = @list.select { |pipeline| pipeline_names.include? pipeline.name }

    ordered_purpose_list = []

    combined_relationships = {}
    pipeline_configs.each do |pc|
      pc.relationships.each do |key, value|
        combined_relationships[key] ||= []
        combined_relationships[key] << value
      end
    end

    all_purposes = (combined_relationships.keys + combined_relationships.values.flatten).uniq

    # Any purposes with no 'child' purposes should go at the end of the list
    without_child = all_purposes.reject { |p| (combined_relationships.key? p) }

    while combined_relationships.size.positive?
      # Find any purposes with no 'parent' purposes - to go on the front of the list
      with_parent = combined_relationships.values.flatten.uniq
      without_parent = all_purposes - with_parent
      raise "Pipeline config can't be flattened into a list of purposes" if without_parent.empty? # important to prevent infinite looping

      ordered_purpose_list += without_parent

      # Delete the nodes that have been added, making the next set of purposes have no parent
      # So we can use the same technique again in the next iteration
      without_parent.each { |n| combined_relationships.delete(n) }

      # Refresh the all_purposes list for the next iteration
      all_purposes = (combined_relationships.keys + combined_relationships.values.flatten).uniq
    end

    # When we've run out of 'parent' purposes, add the final ones on the end
    ordered_purpose_list += without_child
    ordered_purpose_list
  end
end
