# frozen_string_literal: true

# Represents a Study in Limber via the Sequencescape API
class Sequencescape::Api::V2::Study < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasPolyMetadata
end
