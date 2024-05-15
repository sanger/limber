# frozen_string_literal: true

# Transfer Requests track transfers between two assets
class Sequencescape::Api::V2::TransferRequest < Sequencescape::Api::V2::Base

  # @!attribute [r] source_asset
  #   @return [Sequencescape::Api::V2::Receptacle] the source Receptacle
  has_one :source_asset, class_name: 'Sequencescape::Api::V2::Receptacle'
end
