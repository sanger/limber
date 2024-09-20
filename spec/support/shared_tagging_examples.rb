# frozen_string_literal: true

RSpec.shared_context 'a tag plate creator' do
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

  let(:tag_layout_template) { json(:tag_layout_template, uuid: tag_template_uuid) }
  let(:enforce_uniqueness) { true }

  let!(:tag_layout_creation_request) do
    # TODO: {Y24-190} Drop this stub when we no longer need to use V1 in #create_labware! in tagged_plate.rb
    stub_api_get(tag_template_uuid, body: tag_layout_template)

    stub_api_post(
      tag_template_uuid,
      payload: {
        tag_layout: {
          plate: tag_plate_uuid,
          user: user_uuid,
          enforce_uniqueness:
        }
      },
      body: '{}'
    )
  end
end
