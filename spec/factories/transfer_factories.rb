# frozen_string_literal: true

FactoryBot.define do
  factory :transfer, class: Sequencescape::Transfer, traits: [:api_object] do
    json_root { 'transfer' }

    transient do
      destination_uuid { 'destination-uuid' }
      source_uuid { 'source-uuid' }
      user_uuid { 'user-uuid' }
    end

    factory :creation_transfer do
      source { associated :plate, uuid: source_uuid }
      destination { associated :plate, uuid: destination_uuid }
    end

    factory :transfer_between_tubes_by_submission do
      source { associated :plate, uuid: source_uuid }
      destination { associated :multiplexed_library_tube, uuid: destination_uuid }
      user { associated :v1_user, uuid: user_uuid }
    end

    factory :transfer_between_specific_tubes do
      source { associated :multiplexed_library_tube, uuid: source_uuid }
      destination { associated :multiplexed_library_tube, uuid: destination_uuid }
      user { associated :v1_user, uuid: user_uuid }
    end

    factory :transfer_to_mx_tubes_by_submission do
      transient do
        target_tubes_count { 2 }
        source_wells { WellHelpers.column_order[0, target_tubes_count] }
      end
      source { associated :plate, uuid: source_uuid }
      user { associated :v1_user, uuid: user_uuid }

      # Transfers to tubes have a hash, which acts as a minimal representation
      # of the tubes and their source wells.
      transfers do
        transfer_hash = {}
        source_wells.each_with_index do |well, i|
          transfer_hash[well] = {
            'uuid' => "child-tube-#{i}",
            'name' => "Child tube #{i}",
            'state' => 'pending',
            'label' => { "text": 'Example purpose', "prefix": 'prefix' },
            'barcode' => {
              'number' => (i + 1).to_s,
              'prefix' => 'NT',
              'two_dimensional' => nil,
              'ean13' => SBCF::SangerBarcode.new(prefix: 'NT', number: i + 1).machine_barcode.to_s,
              'type' => 2
            }
          }
        end
        transfer_hash
      end
    end

    factory :transfer_collection do
      size { 2 }

      transient do
        json_root { nil }
        resource_actions { %w[read first last] }
        associated_on { 'transfers_to_tubes' }
        plate_uuid   { SecureRandom.uuid }
        # While resources can be paginated, wells wont be.
        # Furthermore, we trust the api gem to handle that side of things.
        resource_url { "#{api_root}#{plate_uuid}/#{associated_on}/1" }
        uuid { nil }
        transfer_factory { :transfer_to_mx_tubes_by_submission }
      end

      transfers do
        Array.new(size) do |_i|
          associated(transfer_factory)
        end
      end
    end
    factory :creation_transfer_collection do
      size { sources.length }

      transient do
        json_root { nil }
        source_uuids { ['source-uuid', 'source-2-uuid'] }
        resource_actions { %w[read first last] }
        associated_on { 'transfers_to_tubes' }
        plate_uuid { SecureRandom.uuid }
        plate { associated :plate, uuid: plate_uuid }
        sources { source_uuids.map { |uuid| associated :plate, uuid: uuid } }
        # While resources can be paginated, wells wont be.
        # Furthermore, we trust the api gem to handle that side of things.
        resource_url { "#{api_root}#{plate_uuid}/#{associated_on}/1" }
        uuid { nil }
        transfer_factory { :creation_transfer }
      end

      transfers do
        sources.map do |source|
          associated(transfer_factory, source: source, destination: plate)
        end
      end
    end
  end
end
