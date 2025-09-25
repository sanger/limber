# frozen_string_literal: true

FactoryBot.define do
  # V2 transfer request
  factory :transfer_request, class: Sequencescape::Api::V2::TransferRequest do
    skip_create

    source_asset { create :well }
    target_asset { create :well }
    submission { create :submission }
    volume { 10.0 }
  end
end
