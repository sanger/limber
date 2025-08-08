# frozen_string_literal: true

module Sequencescape::Api::V2::Shared
  # Include in an API V2 class that has a purpose to set up some standard behaviour
  module HasPurpose
    extend ActiveSupport::Concern

    included { has_one :purpose }

    # Ideally purpose would be required by labware, but apparently
    # we have some tubes without a purpose. So we use a fallback here
    def purpose_name
      purpose&.name || Sequencescape::Api::V2::Purpose::UNKNOWN
    end
  end
end
