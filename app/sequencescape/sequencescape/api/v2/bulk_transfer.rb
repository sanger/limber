# frozen_string_literal: true

# Represents a bulk transfer in Limber via the Sequencescape API
class Sequencescape::Api::V2::BulkTransfer < Sequencescape::Api::V2::Base
  has_many :transfers, class_name: 'Sequencescape::Api::V2::Transfer'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
