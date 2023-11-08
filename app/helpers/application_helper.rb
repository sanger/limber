# frozen_string_literal: true

module ApplicationHelper # rubocop:todo Style/Documentation
  module DeploymentInfo # rubocop:todo Style/Documentation
    begin
      require './lib/deployed_version'
    rescue LoadError
      module Deployed
        VERSION_ID = 'LOCAL'
        VERSION_STRING = "Limber LOCAL [#{ENV.fetch('RACK_ENV', nil)}]"
      end
    end

    def version_information
      # Provides a quick means of checking the deployed version
      Deployed::VERSION_STRING
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

  def each_robot(&block)
    Robots.each_robot(&block)
  end

  # Return a list of unique pipeline group names
  def pipeline_groups
    return [] if Settings.pipelines.list.empty?
    Settings.pipelines.map(&:pipeline_group).uniq.sort
  end
end
