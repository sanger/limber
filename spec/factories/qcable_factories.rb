# frozen_string_literal: true

FactoryBot.define do
  factory :qcable, class: Limber::Qcable, traits: %i[api_object barcoded] do
    with_belongs_to_associations 'lot', 'qcable_creator', 'asset'
    json_root { 'qcable' }

    state { 'available' }

    transient do
      barcode_prefix { 'DN' }
      barcode_type { 1 }
    end

    factory :tag_plate_qcable do
      transient do
        asset_uuid { 'tag-plate-uuid' }
      end
    end
    factory :tag2_tube_qcable do
      transient do
        barcode_prefix { 'NT' }
        asset_uuid { 'tag-tube-uuid' }
      end
    end
  end

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
