# frozen_string_literal: true

# A PipelineList contains all registered {Pipeline pipelines} and is typically
# populated from config/pipelines/*.yml by {ConfigLoader::PipelinesLoader} during
# initialization.
class PipelineList
  attr_reader :list

  delegate_missing_to :list

  def initialize(list = {})
    @list = list.map { |pipeline_name, pipeline_config| Pipeline.new(pipeline_config.merge(name: pipeline_name)) }
  end

  # Returns an array of all pipelines that are 'active' for a particular piece of
  # labware. Normally, an 'active' pipeline is one where one or more active requests on the
  # plate meet the filter criteria.
  # If a pipeline has no filter criteria, it will also be considered 'active' for the labware.
  def active_pipelines_for(labware)
    @list.select { |pipeline| pipeline.active_for?(labware) }
  end

  # For the given pipeline group
  # return a object with key: group, and value: list of the pipeline names in that group
  # e.g {"Bespoke Chromium 3pv2"=>["Bespoke Chromium 3pv2", "Bespoke Chromium 3pv2 MX"]}
  def build_pipeline_groups(pipeline_group)
    pipeline_configs = @list.select { |pipeline| pipeline.pipeline_group == pipeline_group }
    pipeline_configs.group_by(&:pipeline_group).transform_values { |pipeline| pipeline.map(&:name) }
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
  # ["LTHR Cherrypick", "LTHR-384 RT", "LTHR-384 RT-Q", "LTHR-384 PCR 1",
  # "LTHR-384 PCR 2", "LTHR-384 Lib PCR 1", "LTHR-384 Lib PCR 2", "LTHR-384 Lib
  # PCR pool"]
  def combine_and_order_pipelines(pipeline_names)
    pipeline_configs = @list.select { |pipeline| pipeline_names.include? pipeline.name }

    combined_relationships = extract_combined_relationships(pipeline_configs)

    flatten_relationships_into_purpose_list(combined_relationships)
  end

  private

  def extract_combined_relationships(pipeline_configs)
    {}.tap do |combined_relationships|
      pipeline_configs.each do |pc|
        pc.relationships.each do |key, value|
          combined_relationships[key] ||= []
          combined_relationships[key] << value
        end
      end
    end
  end

  def flatten_relationships_into_purpose_list(relationship_config) # rubocop:todo Metrics/MethodLength
    ordered_purpose_list = []

    # Any purposes with no 'child' purposes should go at the end of the list
    without_child = find_purposes_without_child(relationship_config)

    while relationship_config.size.positive?
      # Find any purposes with no 'parent' purposes - to go on the front of the list
      without_parent = find_purposes_without_parent(relationship_config)

      if without_parent.empty?
        # important to prevent infinite looping
        raise "Pipeline config can't be flattened into a list of purposes"
      end

      ordered_purpose_list += without_parent

      # Delete the nodes that have been added, making the next set of purposes
      # have no parent So we can use the same technique again in the next
      # iteration
      without_parent.each { |n| relationship_config.delete(n) }
    end

    # When we've run out of 'parent' purposes, add the final ones on the end
    ordered_purpose_list + without_child
  end

  def find_purposes_without_child(relationship_config)
    # reject purposes that are a 'key' in the config, meaning they have a child
    extract_purposes_from_relationships(relationship_config).reject { |p| (relationship_config.key? p) }
  end

  def extract_purposes_from_relationships(relationship_config)
    (relationship_config.keys + relationship_config.values.flatten).uniq
  end

  def find_purposes_without_parent(relationship_config)
    all_purposes = extract_purposes_from_relationships(relationship_config)
    with_parent = find_purposes_with_parent(relationship_config)

    all_purposes - with_parent
  end

  def find_purposes_with_parent(relationship_config)
    # all purposes that are 'values' in the config have a parent
    relationship_config.values.flatten.uniq
  end
end
