#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.

class ApplicationController < ActionController::Base
  include Sequencescape::Api::Rails::ApplicationController
  include SessionHelper

  delegate :api_connection_options, :to => 'Limber::Application.config'

  protect_from_forgery
end
