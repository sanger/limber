# frozen_string_literal: true

# Transfer Requests track transfers between two assets
class Sequencescape::Api::V2::TransferRequest < Sequencescape::Api::V2::Base
  has_one :source_asset, class_name: 'Sequencescape::Api::V2::Receptacle'
  has_one :target_asset, class_name: 'Sequencescape::Api::V2::Receptacle'
  has_one :submission, class_name: 'Sequencescape::Api::V2::Submission'
end
