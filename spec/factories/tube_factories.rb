
# frozen_string_literal: true
FactoryGirl.define do

  factory :multiplexed_library_tube, class: Limber::MultiplexedLibraryTube, traits: [:api_object, :barcoded] do
    json_root 'multiplexed_library_tube'

    transient do
      barcode_prefix 'NT'
      barcode_type 1
      purpose_uuid 'example-purpose-uuid'
      purpose_name 'Example Purpose'
      stock_plate_barcode 2
    end

    with_has_many_associations 'requests', 'qc_files'

    purpose do
      {
        'uuid' => purpose_uuid, 'name' => purpose_name
      }
    end

    stock_plate do
      sp = associated(:stock_plate, barcode_number: stock_plate_barcode)
      { name: sp[:name], barcode: sp[:barcode] }
    end

    created_at { Time.current }
    updated_at { Time.current }

    factory :tube, class: Limber::Tube, traits: [:api_object, :barcoded] do
    end
  end

  factory :tube_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
    size 2

    transient do
      json_root nil
      resource_actions %w(read first last)
      purpose_uuid { SecureRandom.uuid }
      # While resources can be paginated, wells wont be.
      # Furthermore, we trust the api gem to handle that side of things.
      resource_url { "#{api_root}#{purpose_uuid}/children/1" }
      uuid nil
      tube_factory :tube
    end

    plate_purposes do
      Array.new(size) { |i| associated(tube_factory, uuid: 'tube-' + i.to_s) }
    end
  end
end
