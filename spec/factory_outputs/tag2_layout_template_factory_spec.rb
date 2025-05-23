# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'tag2 layout template factory' do
  subject { json(:tag2_layout_template, uuid: 'tag2-layout-template-uuid') }

  let(:json_content) do
    '{
        "tag2_layout_template": {
          "actions": {
            "read": "http://example.com:3000/tag2-layout-template-uuid",
            "create": "http://example.com:3000/tag2-layout-template-uuid"
          },

          "uuid": "tag2-layout-template-uuid",
          "name": "Test tag2 layout",

          "tag": {
            "name": "Tag",
            "oligo": "AAA"
          }
        }
    }'
  end

  it 'matches the expected json' do
    expect(JSON.parse(subject)['tag2_layout_template']).to eq JSON.parse(json_content)['tag2_layout_template']
  end
end
