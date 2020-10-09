# frozen_string_literal: true

FactoryBot.define do
  # V1 transfer templates.
  # Transfer template are used to create transfers from a source labware
  # to a target labware with a pre-defined set of attributes
  # Strongly caution against using these for newer work, as they reduce flexibility
  # when it comes to things like 96-384 well differences
  factory :transfer_template, class: Sequencescape::TransferTemplate, traits: [:api_object] do
    json_root { 'transfer_template' }
    name { 'Test transfers' }
    named_actions { ['preview'] }
    resource_actions { %w[read create] }
    transfers { { 'A1' => 'A1', 'B1' => 'B1' } }
    uuid { 'transfer-template-uuid' }

    # Used at end of ISC pipeline to transfer into tubes
    factory :transfer_wells_to_mx_library_tubes_by_submission do
      name { 'Transfer wells to MX library tubes by submission' }
      uuid { 'transfer-to-mx-tubes-on-submission' }
      transfers { nil }
    end

    # Used in GBS pipleine to pool 1 or more whole plates into
    # tubes
    factory :whole_plate_to_tube do
      name { 'Whole plate to tube' }
      uuid { 'whole-plate-to-tube' }
      transfers { nil }
    end
  end
end
