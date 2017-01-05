# frozen_string_literal: true
require 'rails_helper'
require 'presenters/plate_presenter'
require_relative 'shared_labware_presenter_examples'

describe Presenters::PlatePresenter do
  # Not sure why this is getting executed twice.
  # Want to get the basics working first though
  has_a_working_api(times: 2)

  let(:labware) do
    build :plate,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 1,
          created_at: '2016-10-19 12:00:00 +0100'
  end

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:summary_tab) do
    [
      ['Barcode', 'DN1 <em>1220000001831</em>'],
      ['Number of wells', '96/96'],
      ['Plate type', purpose_name],
      ['Current plate state', state],
      ['Input plate barcode', 'DN2 <em>1220000002845</em>'],
      ['Created on', '2016-10-19']
    ]
  end

  let(:expected_requests_for_summary) do
    stub_request(:get, labware.wells.send(:actions).read)
      .to_return(status: 200, body: json(:well_collection), headers: { 'content-type' => 'application/json' })
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

  it 'returns label attributes' do
    expected_label = { top_left: Date.today.strftime('%e-%^b-%Y'),
                       bottom_left: 'DN 1',
                       top_right: 'DN2',
                       bottom_right: 'Limber Cherrypicked',
                       barcode: '1220000001831' }
    expect(subject.label_attributes).to eq(expected_label)
  end

  it_behaves_like 'a labware presenter'
end
