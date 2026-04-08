# frozen_string_literal: true

# Sequencescape::Api::V2::Tag
class Sequencescape::Api::V2::Tag < Sequencescape::Api::V2::Base
  DEFAULT_INCLUDES = [].freeze

  belongs_to :tag_group
end
