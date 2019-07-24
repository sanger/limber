# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'tag layout template factory' do
  subject do
    json(
      :tag_layout_template,
      uuid: 'tag-layout-template-uuid',
      size: 2
    )
  end

  let(:json_content) do
    %({
        "tag_layout_template": {
          "actions": {
            "read": "http://example.com:3000/tag-layout-template-uuid",
            "create": "http://example.com:3000/tag-layout-template-uuid"
          },

          "uuid": "tag-layout-template-uuid",
          "name": "Test tag layout",
          "direction": "column",
          "walking_by": "wells of plate",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1": "T",
              "2": "C"
            }
          }
        }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['tag_layout_template']).to eq JSON.parse(json_content)['tag_layout_template']
  end
end
