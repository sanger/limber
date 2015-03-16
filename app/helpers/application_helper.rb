#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2014 Genome Research Ltd.
module ApplicationHelper

  module DeploymentInfo

    begin
      require './lib/deployed_version'
    rescue LoadError
        module Deployed
          VERSION_ID = 'LOCAL'
          VERSION_STRING = "Illumina Pipeline App LOCAL [#{ENV['RACK_ENV']}]"
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
end
