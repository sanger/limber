# frozen_string_literal: true
require 'rails_helper'
require 'presenters/plate_presenter'
require_relative 'shared_labware_presenter_examples'

describe Presenters::PlatePresenter do
  # Not sure why this is getting executed twice.
  # Want to get the basics working first though
  has_a_working_api(times: 2)

  let(:labware) do
    build :plate, purpose_name: title, state: state, barcode_number: 1
  end

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:summary_tab) do
    [
      ['Barcode', 'DN1 <em>1220000001831</em>'],
      ['Number of wells', '96/ 96'],
      ['Plate type', purpose_name],
      ['Current plate state', state],
      ['Input plate barcode', 'DN1 1220000001831'],
      ['Created on', '2016-10-19']
    ]
  end

  let(:expected_requests_for_summary) do
    pending 'The well facotries'
    stub_request(:get, labware.wells.send(:actions).read)
      .to_return(status: 200, body: '{}', headers: {})
  end

  subject do
    Presenters::PlatePresenter.new(
      api:     api,
      labware: labware
    )
  end

  it 'returns plate' do
    expect(subject.plate).to eq(labware)
  end

  it_behaves_like 'a labware presenter'
end
