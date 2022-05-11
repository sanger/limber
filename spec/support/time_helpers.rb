# frozen_string_literal: true

require 'active_support'
require 'active_support/testing/time_helpers'

RSpec.configure { |config| config.include ActiveSupport::Testing::TimeHelpers }
