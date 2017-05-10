# frozen_string_literal: true

require 'rails_helper'

describe 'qc file factory' do
  subject do
    json(
      :qc_file,
      uuid: 'example-qc-file-uuid',
      filename: 'example_file.txt'
    )
  end

  let(:json_content) do
    %({
      "qc_file":
        {
          "filename":"example_file.txt",
          "actions":{"read":"http://example.com:3000/example-qc-file-uuid"},
          "uuid":"example-qc-file-uuid"
        }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['qc_file']).to eq JSON.parse(json_content)['qc_file']
  end
end
