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
end
