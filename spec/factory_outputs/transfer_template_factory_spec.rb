# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'transfer_template factory' do
  subject do
    json(
      :transfer_template,
      uuid: 'example-transfer-template-uuid',
      transfers: { 'A1' => 'A1', 'B1' => 'B1', 'C1' => 'C1' }
    )
  end

  let(:json_content) do
    %({
        "transfer_template": {
          "actions": {
            "read": "http://example.com:3000/example-transfer-template-uuid",
            "create": "http://example.com:3000/example-transfer-template-uuid",
            "preview": "http://example.com:3000/example-transfer-template-uuid/preview"
          },

          "uuid": "example-transfer-template-uuid",
          "name": "Test transfers",
          "transfers": {
            "A1": "A1",
            "B1": "B1",
            "C1": "C1"
          }
        }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['transfer_template']).to eq JSON.parse(json_content)['transfer_template']
  end
end
