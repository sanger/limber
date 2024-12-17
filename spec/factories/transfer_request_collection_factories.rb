# frozen_string_literal: true

FactoryBot.define do
  # API V1 collection of multiple transfer requests
  # This allows easy creation of multiple transfers between arbitrary receptacles
  factory :transfer_request_collection, class: Sequencescape::TransferRequestCollection, traits: [:api_object] do
    json_root { 'transfer_request_collection' }

    transient do
      # The number of transfers to create (Will be generated in column order for wells)
      transfer_count { 2 }

      # Number of different targets expected. For example, setting this to 1 will result in
      # transfers into a single target, wheas setting it to the same as transfer count will
      # result in lots of 1 to 1 transfers. Between this you'll get multiple different pools
      number_of_targets { 1 }

      # The well on the source plate that transfers will begin from (0 for A1)
      initial_well { 0 }

      # Offset the uuid generation for expected target assets.
      initial_target { 0 }
      source_plate_barcode { 'DN2' }
    end

    transfer_requests do
      Array.new(transfer_count) do |i|
        target_number = ((number_of_targets / transfer_count.to_f) * i).floor + initial_target
        {
          source_asset: {
            uuid: "example-well-uuid-#{i + initial_well}"
          },
          target_asset: {
            uuid: "target-#{target_number}-uuid"
          }
        }
      end
    end

    target_tubes do
      Array.new(number_of_targets) do |i|
        wells_per_transition = (transfer_count / number_of_targets.to_f).ceil
        from = WellHelpers.column_order[initial_well + (i * wells_per_transition)]
        last_well = initial_well + ((i + 1) * wells_per_transition) - 1
        last_well_rounded = [last_well, (transfer_count + initial_well - 1)].min
        to = WellHelpers.column_order[last_well_rounded]
        associated(:tube, name: "#{source_plate_barcode} #{from}:#{to}", uuid: "target-#{initial_target + i}-uuid")
      end
    end
  end

  # A collection of transfer request collections.
  # Basically what happens if you transfer out of a plate multiple times
  factory :transfer_request_collection_collection, class: Sequencescape::Api::PageOfResults, traits: [:api_object] do
    size { 2 }

    transient do
      json_root { nil }
      resource_actions { %w[read first last] }
      plate_uuid { SecureRandom.uuid }

      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}#{plate_uuid}/transfer_request_collections/1" }
      uuid { nil }
    end

    transfer_request_collections do
      Array.new(size) { |i| associated(:transfer_request_collection, initial_well: i * 2, initial_target: i) }
    end
  end
end
