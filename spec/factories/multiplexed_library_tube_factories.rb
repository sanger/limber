
# frozen_string_literal: true
FactoryGirl.define do
  factory :multiplexed_library_tube, class: Limber::MultiplexedLibraryTube, traits: [:api_object, :barcoded] do
    json_root 'multiplexed_library_tube'

    transient do
      barcode_prefix 'NT'
      barcode_type 1
      purpose_uuid 'example-purpose-uuid'
    end

    purpose do
      {
        'uuid' => purpose_uuid
      }
    end
  end
end
