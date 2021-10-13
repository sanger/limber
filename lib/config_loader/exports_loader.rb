# frozen_string_literal: true

require_relative 'base'

module ConfigLoader
  # Loads the pipeline configurations
  class ExportsLoader < ConfigLoader::Base
    self.config_folder = 'exports'

    attr_reader :config
  end
end
