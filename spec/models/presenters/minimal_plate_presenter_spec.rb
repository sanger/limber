# frozen_string_literal: true

require 'rails_helper'
require 'presenters/plate_presenter'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::MinimalPlatePresenter do
  has_a_working_api

  let(:labware) do
    create :v2_plate,
           purpose_name: purpose_name,
           state: state,
           barcode_number: 1,
           pool_sizes: [2, 2],
           created_at: '2016-10-19 12:00:00 +0100'
  end

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:summary_tab) do
    [
      ['Barcode', 'DN1 <em>1220000001831</em>'],
      ['Number of wells', 96],
      ['Plate type', purpose_name],
      ['Current plate state', state],
      ['Input plate barcode', 'DN2 <em>1220000002845</em>'],
      ['PCR Cycles', '10'],
      ['Created on', '2016-10-19']
    ]
  end

  before do
    create :purpose_config, uuid: labware.purpose.uuid
    create :stock_plate_config, uuid: 'stock-plate-purpose-uuid'
  end

  subject(:presenter) do
    Presenters::MinimalPlatePresenter.new(
      api: api,
      labware: labware
    )
  end

  it 'returns label attributes' do
    expected_label = { top_left: Time.zone.today.strftime('%e-%^b-%Y'),
                       bottom_left: 'DN1S',
                       top_right: 'DN2T',
                       bottom_right: 'WGS Limber example purpose',
                       barcode: '1220000001831' }
    expect(subject.label.attributes).to eq(expected_label)
  end

  it_behaves_like 'a labware presenter'

  context 'a plate with conflicting pools' do
    let(:labware) do
      create :v2_plate, pool_sizes: [2, 2], pool_prc_cycles: [10, 6]
    end

    it 'reports as invalid' do
      expect(subject).to_not be_valid
    end

    it 'reports the error' do
      subject.valid?
      expect(subject.errors.full_messages).to include('Pcr cycles specified is not consistent across the plate.')
    end
  end
end
