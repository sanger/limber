# frozen_string_literal: true
require 'rails_helper'


describe 'plate factory' do

  subject { json :plate }

  let(:json_content) {%Q{
      {
        "plate":{"state":"pending", "stock_plate":{"barcode":{"prefix":"DN", "number":"10"}}, "barcode":{"prefix":"DN", "number":"123", "ean13":"1234567890123"}, "label":{"prefix":"Limber", "text":"Cherrypicked"}}
      }
  }}

  it 'should match the expected json' do
    expect(JSON.parse(subject)).to eq JSON.parse(json_content)
  end
end
