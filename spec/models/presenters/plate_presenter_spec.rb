# frozen_string_literal: true
require 'rails_helper'
require './app/models/presenters/plate_presenter'

shared_examples 'a labware presenter' do
  it 'returns labware' do
    expect(subject.labware).to eq(labware)
  end

  it 'provides a title' do
    expect(subject.title).to eq(title)
  end

  it 'has a state' do
    expect(subject.state).to eq(state)
  end

  it 'has a summary' do
    expect() { |b| subject.summary(&b) }.to yield_successive_args(*summary_tab)
  end
end

describe Presenters::PlatePresenter do
  # Not sure why this is getting executed twice.
  # Want to get the basics working first though
  has_a_working_api(times: 2)

  let(:labware) do
    build :plate, purpose_name: title, state: state, barcode_number: 1
  end

  let(:title) { 'Limber example purpose' }
  let(:state) { 'pending' }
  let(:summary_tab) {[
      ['Barcode','DN1 <em>1220000001831</em>']
  ]}

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
