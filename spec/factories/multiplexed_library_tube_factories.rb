
# frozen_string_literal: true
FactoryGirl.define do
  factory :multiplexed_library_tube, class: Limber::MultiplexedLibraryTube, traits: [:api_object, :barcoded] do
    json_root 'multiplexed_library_tube'

    transient do
      barcode_prefix 'NT'
      barcode_type 1
      purpose_uuid 'example-purpose-uuid'
      purpose_name 'Example Purpose'
    end

    with_has_many_associations 'requests', 'qc_files'

    purpose do
      {
        'uuid' => purpose_uuid, 'name' => purpose_name
      }
    end

    created_at { Time.current }
    updated_at { Time.current }
  end
end
