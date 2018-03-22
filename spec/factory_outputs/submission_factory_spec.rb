# frozen_string_literal: true

require 'rails_helper'

describe 'submission factories' do
  describe 'basic' do
    subject do
      json(
        :submission, uuid: 'sub-uuid', orders: [{ 'uuid' => 'order-uuid' }]
      )
    end

    let(:json_content) do
      %({
          "submission":{
            "uuid":"sub-uuid",
            "actions":{"read":"http://example.com:3000/sub-uuid","submit":"http://example.com:3000/sub-uuid/submit"},
            "orders": [{"uuid":"order-uuid"}],
            "state": "building"
          }
        })
    end

    it 'should match the expected json' do
      expect(JSON.parse(subject)).to eq JSON.parse(json_content)
    end
  end
end
