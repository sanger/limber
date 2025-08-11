# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::PcrPoolXpPresenter do
  subject { described_class.new(labware:) }

  let(:labware) do
    build :tube, purpose_name: purpose_name, state: state, barcode_number: 6, created_at: '2016-10-19 12:00:00 +0100'
  end

  before { create(:stock_plate_config, uuid: 'stock-plate-purpose-uuid') }

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'passed' }
  let(:summary_tab) do
    [
      ['Barcode', 'NT6T <em>3980000006844</em>'],
      ['Tube type', purpose_name],
      ['Current tube state', state],
      ['Input plate barcode', labware.stock_plate.human_barcode],
      ['Created on', '2016-10-19']
    ]
  end
  let(:sidebar_partial) { 'default' }

  it_behaves_like 'a labware presenter'

  it 'has export_to_traction option' do
    expect(subject.export_to_traction).to be_truthy
  end

  it 'has no export_to_traction option' do
    labware.state = 'pending'
    expect(subject.export_to_traction).to be_falsey
  end
end
