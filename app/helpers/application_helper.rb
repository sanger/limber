# frozen_string_literal: true

module ApplicationHelper # rubocop:todo Style/Documentation
  module DeploymentInfo # rubocop:todo Style/Documentation
    begin
      require './lib/deployed_version'
    rescue LoadError
      module DeployedVersion
        VERSION_ID = 'LOCAL'
        VERSION_STRING = "Limber LOCAL [#{ENV.fetch('RACK_ENV', nil)}]".freeze
      end
    end

    def version_information
      # Provides a quick means of checking the deployed version
      DeployedVersion::VERSION_STRING
    end
  end
  include DeploymentInfo

  # Easy access to the api from the console
  def api
    Sequencescape::Api.new(Limber::Application.config.api.v1.connection_options.dup)
  end

  def environment
    Rails.env
  end

  def each_robot(&)
    Robots.each_robot(&)
  end

  # Return a list of unique pipeline group names
  def pipeline_groups
    return [] if Settings.pipelines.list.empty?

    Settings.pipelines.map(&:pipeline_group).uniq.sort
  end

  # Returns the appropriate icon suffix for the current environment
  # Returns empty string for production
  # Returns "-#{environment}" for training, staging
  # Returns "-development" for any other environment
  # @return [String] The suffix to append to the icon name
  def icon_suffix
    environment = Rails.env
    case environment
    when 'production'
      ''
    when 'training', 'staging'
      "-#{environment}"
    else
      '-development'
    end
  end

  # Return the appropriate favicon for the current environment
  # @return [String] The path to the favicon
  def favicon
    "favicon#{icon_suffix}.ico"
  end

  # Return the appropriate apple-touch-icon for the current environment
  # @return [String] The path to the apple-touch-icon
  def apple_touch_icon
    "apple-touch-icon#{icon_suffix}.png"
  end
end
