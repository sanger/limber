# frozen_string_literal: true

FactoryBot.define do
  # API V2 QCable
  factory :v2_qcable, class: Sequencescape::Api::V2::Qcable, traits: [:barcoded_v2] do
    skip_create

    uuid
    state { 'available' }

    transient do
      labware { create :v2_plate }
      lot { create :v2_lot }
    end

    after(:build) do |qcable, factory|
      qcable._cached_relationship(:labware) { factory.labware } if factory.labware
      qcable._cached_relationship(:lot) { factory.lot } if factory.lot
      qcable._cached_relationship(:asset) { factory.labware } if factory.labware # alias for labware
    end
  end

  factory :v2_lot, class: Sequencescape::Api::V2::Lot do
    skip_create

    sequence(:lot_number) { |n| "UAT12345.#{n}" }

    transient do
      lot_type { create :v2_lot_type }
      template { create :v2_tag_layout_template }
    end

    after(:build) do |lot, factory|
      lot._cached_relationship(:lot_type) { factory.lot_type } if factory.lot_type
      lot._cached_relationship(:template) { factory.template } if factory.template
    end
  end

  factory :v2_lot_type, class: Sequencescape::Api::V2::LotType do
    skip_create

    sequence(:name) { |n| "LotType#{n}" }

    transient { target_purpose { create :v2_purpose } }

    after(:build) do |lot_type, factory|
      lot_type._cached_relationship(:target_purpose) { factory.target_purpose } if factory.target_purpose
    end
  end

  # API V1 Qcable (Records the QC status of eg. a tag plate)
  factory :qcable, class: Qcable, traits: %i[api_object barcoded] do
    with_belongs_to_associations 'lot', 'qcable_creator', 'asset'
    json_root { 'qcable' }

    state { 'available' }

    transient do
      barcode_prefix { 'DN' }
      barcode_type { 1 }
    end

    # API V1 tag plate qcable
    factory :tag_plate_qcable do
      transient { asset_uuid { 'tag-plate-uuid' } }
    end

    # API V1 tag2 tube qcable
    factory :tag2_tube_qcable do
      transient do
        barcode_prefix { 'NT' }
        asset_uuid { 'tag-tube-uuid' }
      end
    end
  end

  # API V1 lot, associated with qcables and contains the information about
  # what templates they are associated with
  factory :lot, class: Sequencescape::Lot, traits: [:api_object] do
    json_root { 'lot' }
    with_has_many_associations 'qcables'
    with_belongs_to_associations 'lot_type', 'template'

    lot_number { '123435' }
    lot_type_name { 'IDT Tags' }
    received_at { '2014-03-27' }
    template_name { 'Sanger_168tags - 10 mer tags in columns ignoring pools (first oligo: ATCACGTT)' }

    factory :tag_lot do
      lot_type_uuid { 'tag-lot-type-uuid' }
      template_uuid { 'tag-layout-template-uuid' }
    end
    factory :tag2_lot do
      lot_type_uuid { 'tag2-lot-type-uuid' }
      lot_type_name { 'Tag 2 Tubes' }
      template_uuid { 'tag2-layout-template-uuid' }
    end
  end

  factory :lot_type, class: Sequencescape::LotType, traits: [:api_object] do
    json_root { 'lot_type' }
    with_has_many_associations 'lots'
    name { 'Lot type' }
    printer_type { '96 Well Plate' }
    qcable_name { 'Tag Plate' }
    template_class { 'TagLayoutTemplate' }

    factory :tag_lot_type do
      uuid { 'tag-lot-type-uuid' }
      qcable_name { 'Tag Plate' }
      template_class { 'TagLayoutTemplate' }
    end

    factory :tag2_lot_type do
      uuid { 'tag2-lot-type-uuid' }
      qcable_name { 'Tag 2 Tube' }
      template_class { 'Tag2LayoutTemplate' }
    end
  end
end
