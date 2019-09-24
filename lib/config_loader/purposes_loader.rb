# frozen_string_literal: true

require_relative 'base'

module ConfigLoader
  # Loads the purpose configurations
  class PurposesLoader < ConfigLoader::Base
    self.config_folder = 'purposes'

    attr_reader :config
  end
end
