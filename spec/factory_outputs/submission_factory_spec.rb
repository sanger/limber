# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'submission factories' do
  describe 'basic' do
    subject { json(:submission, uuid: 'sub-uuid', orders: [{ 'uuid' => 'order-uuid' }]) }

    let(:json_content) do
      '{
          "submission":{
            "uuid":"sub-uuid",
            "actions":{"read":"http://example.com:3000/sub-uuid","submit":"http://example.com:3000/sub-uuid/submit"},
            "orders": [{"uuid":"order-uuid"}],
            "state": "building"
          }
        }'
    end

    it 'should match the expected json' do
      expect(JSON.parse(subject)).to eq JSON.parse(json_content)
    end
  end
end
