# frozen_string_literal: true

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
