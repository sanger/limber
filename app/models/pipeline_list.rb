# frozen_string_literal: true

# A PipelineList contains all registered {Pipeline pipelines} and is typically
# populated from config/pipelines/*.yml by {ConfigLoader::PipelinesLoader} during
# initialization.
class PipelineList
  attr_reader :list

  # When calling a PipelineList object, if method doesn't exist, call on the @list object
  # e.g Settings.pipelines.group_by(&:pipeline_group)
  # is the equalivent of Settings.pipelines.list.group_by(&:pipeline_group)
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
  # return a list of the pipeline names in that group
  # e.g "Bespoke Chromium 3pv2"
  #   =>["Bespoke Chromium 3pv2", "Bespoke Chromium 3pv2 MX"]
  def retrieve_pipeline_config_for_group(pipeline_group)
    @list.select { |pipeline| pipeline.pipeline_group == pipeline_group }.map(&:name)
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

  # Orders the purposes within a pipeline based on the relationships.
  #
  # @param pipeline_name [String] The name of the pipeline to order.
  #
  # @return [Array] Returns an array of purposes, ordered based on the relationships of the pipeline.
  def order_pipeline(pipeline_name)
    pipeline_config = @list.find { |pipeline| pipeline.name == pipeline_name }
    relationship_config = pipeline_config.relationships
    flatten_relationships_into_purpose_list(relationship_config)
  end

  # Given a list of purposes and pipelines of interest, show which purposes are
  # parts of which pipelines and their parents and children
  # e.g:
  # {
  #   "Purpose 1" => {
  #     "Pipeline A" => {
  #       "parents" => [],
  #       "child" => "Purpose 2"
  #     }
  #   },
  #   "Purpose 2" => {
  #     "Pipeline A" => {
  #       "parents" => ["Purpose 1"],
  #       "child" => "Purpose 3"
  #     },
  #     "Pipeline B" => {
  #       "parents" => ["Purpose 1"],
  #       "child" => nil
  #     }
  #   },
  # }
  def purpose_to_pipelines_map(purposes, pipeline_names)
    pipeline_configs = select_pipelines(pipeline_names)
    purposes.each_with_object({}) do |purpose, result|
      pipelines_with_purpose = select_pipelines_with_purpose(pipeline_configs, purpose)
      pipelines_with_purpose.each do |pipeline|
        result[purpose] ||= {}
        result[purpose][pipeline.name] = {
          parents: pipeline.relationships.select { |_k, v| v == purpose }.keys,
          child: pipeline.relationships[purpose] # should only ever be one child per purpose in a Limber pipeline
        }
      end
    end
  end

  private

  # Given a list of pipeline names, return the pipelines with those names
  def select_pipelines(pipeline_names)
    @list.select { |pipeline| pipeline_names.include? pipeline.name }
  end

  # Given a list of pipeline configs and a purpose, return the pipelines that
  # have that purpose in their relationships
  def select_pipelines_with_purpose(pipeline_configs, purpose)
    pipeline_configs.select { |pipeline| purpose_in_relationships?(pipeline, purpose) }
  end

  # Given a list of pipeline configs, extract the relationships and combine them
  # into a single hash
  # eg:
  # [#<Pipeline:A>, #<Pipeline:B>] => { 'Purpose 1' => ['Purpose 2', 'Purpose 3'] }
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

  # Checks if a given purpose is present in a pipeline.
  #
  # @param pipeline [Object] The pipeline to check.
  # @param purpose [String] The purpose to look for.
  #
  # @return [Boolean] Returns true if the purpose is present in the the pipeline, false otherwise.
  def purpose_in_relationships?(pipeline, purpose)
    (pipeline.relationships.keys + pipeline.relationships.values).include?(purpose)
  end

  def flatten_relationships_into_purpose_list(relationship_config_original)
    # Make a copy of the config so we can delete nodes as we go
    relationship_config = relationship_config_original.dup
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
