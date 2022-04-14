# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'qc file factory' do
  subject { json(:qc_file, uuid: 'example-qc-file-uuid', filename: 'example_file.txt') }

  let(:json_content) do
    '{
      "qc_file":
        {
          "filename":"example_file.txt",
          "size": 123,
          "actions":{"read":"http://example.com:3000/example-qc-file-uuid"},
          "uuid":"example-qc-file-uuid",
          "created_at": "2017-06-29T09:31:59.000+01:00"
        }
    }'
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['qc_file']).to eq JSON.parse(json_content)['qc_file']
  end
end
