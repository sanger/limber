# frozen_string_literal: true

# bait library layout resource
class Sequencescape::Api::V2::BaitLibraryLayout < Sequencescape::Api::V2::Base
  custom_endpoint :preview, on: :collection, request_method: :post
end
