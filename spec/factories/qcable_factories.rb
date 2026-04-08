# frozen_string_literal: true

FactoryBot.define do
  # API V2 QCable
  factory :qcable, class: Sequencescape::Api::V2::Qcable, traits: [:barcoded] do
    skip_create

    uuid
    state { 'available' }

    transient do
      labware { create :plate }
      lot { create :lot }
    end

    after(:build) do |qcable, factory|
      qcable._cached_relationship(:labware) { factory.labware } if factory.labware
      qcable._cached_relationship(:lot) { factory.lot } if factory.lot
      qcable._cached_relationship(:asset) { factory.labware } if factory.labware # alias for labware
    end
  end

  factory :lot, class: Sequencescape::Api::V2::Lot do
    skip_create

    sequence(:lot_number) { |n| "UAT12345.#{n}" }

    transient do
      lot_type { create :lot_type }
      template { create :tag_layout_template }
    end

    after(:build) do |lot, factory|
      lot._cached_relationship(:lot_type) { factory.lot_type } if factory.lot_type
      lot._cached_relationship(:template) { factory.template } if factory.template
    end
  end

  factory :lot_type, class: Sequencescape::Api::V2::LotType do
    skip_create

    sequence(:name) { |n| "LotType#{n}" }

    transient { target_purpose { create :purpose } }

    after(:build) do |lot_type, factory|
      lot_type._cached_relationship(:target_purpose) { factory.target_purpose } if factory.target_purpose
    end
  end
end
