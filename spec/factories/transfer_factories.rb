
# frozen_string_literal: true
FactoryGirl.define do
  factory :transfer, class: Sequencescape::Transfer, traits: [:api_object] do
    json_root 'transfer'

    transient do
      destination_uuid 'destination-uuid'
      source_uuid 'source-uuid'
      user_uuid 'user-uuid'
    end

    factory :transfer_between_tubes_by_submission do
      source { associated :plate, uuid: source_uuid }
      destination { associated :multiplexed_library_tube, uuid: destination_uuid }
      user { associated :user, uuid: user_uuid }
    end
  end
end
