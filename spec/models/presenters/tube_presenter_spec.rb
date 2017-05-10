# frozen_string_literal: true

require 'rails_helper'
require 'presenters/tube_presenter'
require_relative 'shared_labware_presenter_examples'

describe Presenters::TubePresenter do
  # Not sure why this is getting executed twice.
  # Want to get the basics working first though
  has_a_working_api(times: 2)

  let(:labware) do
    build :multiplexed_library_tube,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 6,
          created_at: '2016-10-19 12:00:00 +0100',
          stock_plate: {
            "barcode": {
              "ean13": '1111111111111',
              "number": '427444',
              "prefix": 'DN',
              "two_dimensional": nil,
              "type": 1
            },
            "uuid": 'example-stock-plate-uuid'
          }
  end

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:summary_tab) do
    [
      ['Barcode', 'NT6 <em>3980000006844</em>'],
      ['Tube type', purpose_name],
      ['Current tube state', state],
      ['Input plate barcode', 'DN427444 <em>1111111111111</em>'],
      ['Created on', '2016-10-19']
    ]
  end

  subject do
    Presenters::TubePresenter.new(
      api:     api,
      labware: labware
    )
  end

  it 'returns tube' do
    expect(subject.tube).to eq(labware)
  end

  it_behaves_like 'a labware presenter'
end
