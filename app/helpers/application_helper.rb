# frozen_string_literal: true

module ApplicationHelper # rubocop:todo Style/Documentation
  module DeploymentInfo # rubocop:todo Style/Documentation
    begin
      require './lib/deployed_version'
    rescue LoadError
      module Deployed
        VERSION_ID = 'LOCAL'
        VERSION_STRING = "Limber LOCAL [#{ENV['RACK_ENV']}]"
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

  def environment_type_class
    Rails.env.production? ? 'production' : 'nonproduction'
  end

  def each_robot(&block)
    Robots.each_robot(&block)
  end

  # Return a list of unique pipeline group names
  def pipeline_groups
    pipeline_groups = Settings.pipelines.group_by(&:pipeline_group).transform_values { |pipeline| pipeline.map(&:name) }
    pipeline_groups.map { |group, _pipeline| group }
  end
end

# default
# pipeline group used when grouping pipelines
# convention, if no group, us same name as pipeline
# on render, if no key, put in seperate grouping
