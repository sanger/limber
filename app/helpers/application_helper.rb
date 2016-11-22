# frozen_string_literal: true

module ApplicationHelper
  module DeploymentInfo
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

  def environment
    Rails.env
  end

  def non_production_class
    Rails.env != 'production' ? 'nonproduction' : ''
  end

  def custom_theme
    yield 'nonproduction' unless Rails.env == 'production'
  end

  def each_robot(&block)
    Robots::Robot.each_robot(&block)
  end
end
