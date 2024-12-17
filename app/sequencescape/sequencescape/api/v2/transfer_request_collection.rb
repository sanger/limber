# frozen_string_literal: true

# Represents a transfer request collection in Limber via the Sequencescape API
class Sequencescape::Api::V2::TransferRequestCollection < Sequencescape::Api::V2::Base
  has_many :target_tubes, class_name: 'Sequencescape::Api::V2::Tube'
  has_many :transfer_requests, class_name: 'Sequencescape::Api::V2::TransferRequest'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
