# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'submission_pool factories' do
  describe 'basic' do
    subject { json(:submission_template, uuid: 'sub-temp', name: 'Test template') }

    let(:json_content) do
      '{
          "order_template":{
            "uuid":"sub-temp",
            "actions":{"read":"http://example.com:3000/sub-temp"},
            "name":"Test template",
            "orders":{
              "actions":{"create":"http://example.com:3000/sub-temp/orders"}
            }
          }
        }'
    end

    it 'should match the expected json' do
      expect(JSON.parse(subject)).to eq JSON.parse(json_content)
    end
  end
end
