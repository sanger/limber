# frozen_string_literal: true

require_relative 'base'

module ConfigLoader
  # Loads the pipeline configurations
  class PipelinesLoader < ConfigLoader::Base
    self.config_folder = 'pipelines'

    attr_reader :config

    def pipelines
      PipelineList.new(config)
    end
  end
end
