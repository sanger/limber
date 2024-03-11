# frozen_string_literal: true

require_relative 'base'

module ConfigLoader
  # Loads the pooling configurations
  class PoolingsLoader < ConfigLoader::Base
    self.config_folder = 'poolings'

    attr_reader :config
  end
end
