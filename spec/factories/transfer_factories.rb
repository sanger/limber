# frozen_string_literal: true

FactoryBot.define do
  # API V2 Transfer
  factory :v2_transfer, class: Sequencescape::Api::V2::Transfer do
    skip_create

    transient do
      user
      source { create :v2_plate }
      destination { create :v2_plate }
    end

    uuid

    user_uuid { user.uuid }
    source_uuid { source.uuid }
    destination_uuid { destination.uuid }
    transfers { { 'A1' => 'A1', 'B1' => 'B1', 'C1' => 'C1' } }

    factory :v2_transfer_to_tubes_by_submission do
      transient do
        destination_tube_count { 2 }
        tubes { create_list(:v2_tube, destination_tube_count) }
        well_coordinates { WellHelpers.column_order[0, destination_tube_count] }
      end

      destination_uuid { nil }

      # Transfers will be a hash with column names as keys and tube-like objects for the values.
      transfers { (0...destination_tube_count).to_h { |i| [well_coordinates[i], { uuid: tubes[i].uuid }] } }
    end

    factory :v2_transfer_between_tubes do
      transient do
        source { create :v2_tube }
        destination { create :v2_tube }
      end

      transfers { nil }
    end
  end
end
