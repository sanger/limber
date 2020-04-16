# frozen_string_literal: true

FactoryBot.define do
  # V2 transfer request
  factory :v2_transfer_request, class: Sequencescape::Api::V2::TransferRequest do
    skip_create

    source_asset { create :v2_well }
    target_asset { create :v2_well }
    submission { create :v2_submission }
    volume { 10.0 }
  end
end
