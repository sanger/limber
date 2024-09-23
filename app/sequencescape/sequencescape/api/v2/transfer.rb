# frozen_string_literal: true

# transfer resource
class Sequencescape::Api::V2::Transfer < Sequencescape::Api::V2::Base
  def self.resource_path
    'transfers/transfers' # Transfers are nested beneath a transfers path.
  end
end
