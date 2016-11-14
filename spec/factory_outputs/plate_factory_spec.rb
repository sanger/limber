# frozen_string_literal: true
require 'rails_helper'


describe 'plate factory' do

  subject { json :plate }

  let(:json_content) {%Q{
      {
        "plate":{"state":"pending"}
      }
  }}

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to eq JSON.parse(json_content)
  end
end
