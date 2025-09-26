# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::MinimalStockPlatePresenter do
  subject(:presenter) { described_class.new(labware:) }

  let(:labware) do
    create :stock_plate,
           purpose_name: purpose_name,
           state: state,
           barcode_number: 1,
           pool_sizes: [2, 2],
           created_at: '2016-10-19 12:00:00 +0100'
  end

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:barcode_string) { 'DN1S' }
  let(:summary_tab) do
    [
      ['Barcode', barcode_string],
      ['Number of wells', 96],
      ['Plate type', purpose_name],
      ['Current plate state', state],
      ['Input plate barcode', barcode_string],
      ['PCR Cycles', '10'],
      ['Created on', '2016-10-19']
    ]
  end
  let(:sidebar_partial) { 'default' }

  before { create :stock_plate_config, uuid: labware.purpose.uuid, name: purpose_name }

  it 'returns label attributes' do
    expected_label = {
      top_left: Time.zone.today.strftime('%e-%^b-%Y'),
      bottom_left: 'DN1S',
      top_right: 'DN1S',
      bottom_right: 'WGS Limber example purpose',
      barcode: 'DN1S'
    }
    expect(subject.label.attributes).to eq(expected_label)
  end

  it_behaves_like 'a labware presenter'
  it_behaves_like 'a stock presenter'

  context 'a plate with conflicting pools' do
    let(:labware) { create :plate, pool_sizes: [2, 2], pool_pcr_cycles: [10, 6] }

    it 'reports as invalid' do
      expect(subject).not_to be_valid
    end

    it 'reports the error' do
      subject.valid?
      expect(subject.errors.full_messages).to include('Pcr cycles are not consistent across the plate.')
    end
  end
end
