# frozen_string_literal: true
require 'rails_helper'

describe 'tag2 layout template factory' do
  subject do
    json(
      :tag2_layout_template,
      uuid: 'tag2-layout-template-uuid'
    )
  end

  let(:json_content) do
    %({
        "tag2_layout_template": {
          "actions": {
            "read": "http://localhost:3000/tag2-layout-template-uuid"
          },

          "uuid": "tag2-layout-template-uuid",
          "name": "Test tag2 layout",

          "tag": {
            "name": "Tag",
            "oligo": "AAA"
          }
        }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['tag2_layout_template']).to eq JSON.parse(json_content)['tag2_layout_template']
  end
end
