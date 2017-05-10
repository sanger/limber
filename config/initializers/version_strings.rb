# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012 Genome Research Ltd.
begin
  require 'deployed_version'
rescue LoadError
  ####################################################
  # Included for compatibility with generated deployed
  # version file
  module Deployed
    ENVIRONMENT = 'Dev'

    VERSION_ID = 'LOCAL'
    VERSION_STRING = "Limber LOCAL [#{Deployed::ENVIRONMENT}]"

    APP_NAME = 'Limber'
    RELEASE_NAME = 'DEV'

    MAJOR = 'x'
    MINOR = 'x'
    EXTRA = 'x'
    BRANCH = ''
    COMMIT = ''
    ABBREV_COMMIT = ''

    require 'ostruct'
    DETAILS = OpenStruct.new(
      name: APP_NAME,
      version: VERSION_ID,
      environment: ENVIRONMENT
    )
  end
  ####################################################
end
