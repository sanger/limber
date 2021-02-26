# frozen_string_literal: true
# frozen_string_literal: true

RSpec.shared_context 'a tag plate creator' do
  # Requests that might get made
  let!(:state_change_tag_plate_request) do
    stub_api_post(
      'state_changes',
      payload: {
        state_change: {
          user: user_uuid,
          target: tag_plate_uuid,
          reason: 'Used in Library creation',
          target_state: 'exhausted'
        }
      },
      body: json(:state_change)
    )
  end

  let!(:plate_conversion_request) do
    stub_api_post(
      'plate_conversions',
      payload: {
        plate_conversion: {
          user: user_uuid,
          target: tag_plate_uuid,
          purpose: child_purpose_uuid,
          parent: plate_uuid
        }
      },
      body: '{}' # We don't care
    )
  end

  let(:expected_transfers) { WellHelpers.stamp_hash(96) }

  let!(:transfer_creation_request) do
    stub_api_get(transfer_template_uuid, body: transfer_template)
    stub_api_post(
      transfer_template_uuid,
      payload: {
        transfer: {
          source: plate_uuid,
          destination: tag_plate_uuid,
          user: user_uuid,
          transfers: expected_transfers
        }
      },
      body: '{}'
    )
  end

  let(:tag_layout_template) { json(:tag_layout_template, uuid: tag_template_uuid) }
  let(:enforce_uniqueness) { true }

  let!(:tag_layout_creation_request) do
    stub_api_get(tag_template_uuid, body: tag_layout_template)
    stub_api_post(
      tag_template_uuid,
      payload: {
        tag_layout: {
          plate: tag_plate_uuid,
          user: user_uuid,
          enforce_uniqueness: enforce_uniqueness
        }
      },
      body: '{}'
    )
  end
end
