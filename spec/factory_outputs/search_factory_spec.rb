# frozen_string_literal: true
require 'rails_helper'

describe 'search factory' do
  subject do
    json(
      :search,
      uuid: 'example-search-uuid',
      name: 'Find assets by barcode'
    )
  end

  let(:json_content) do
    %({
      "search": {
        "actions": {
          "read": "http://localhost:3000/example-search-uuid",
          "first": "http://localhost:3000/example-search-uuid/first",
          "last": "http://localhost:3000/example-search-uuid/last",
          "all": "http://localhost:3000/example-search-uuid/all"
        },

        "uuid": "example-search-uuid",
        "name": "Find assets by barcode"
      }
    })
  end

  it 'should match the expected json' do
    expect(JSON.parse(subject)['search']).to eq JSON.parse(json_content)['search']
  end
end
