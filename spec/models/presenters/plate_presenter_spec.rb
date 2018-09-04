# frozen_string_literal: true

require 'rails_helper'
require 'presenters/plate_presenter'
require_relative 'shared_labware_presenter_examples'

describe Presenters::PlatePresenter do
  has_a_working_api

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
      ['PCR Cycles', '10'],
      ['Created on', '2016-10-19']
    ]
  end

  let(:labware) do
    build :plate,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 1,
          pool_sizes: [2, 2],
          created_at: '2016-10-19 12:00:00 +0100'
  end

  before(:each) do
    stub_api_get(labware.uuid, 'wells', body: json(:well_collection))
    Settings.purposes = {}
  end

  subject(:presenter) do
    Presenters::PlatePresenter.new(
      api:     api,
      labware: labware
    )
  end

  it 'returns PlateLabel attributes when PlateLabel is defined in the purpose settings' do
    Settings.purposes[labware.purpose.uuid] = build(:purpose_config)
    expected_label = { top_left: Time.zone.today.strftime('%e-%^b-%Y'),
                       bottom_left: 'DN 1',
                       top_right: 'DN2',
                       bottom_right: 'Limber Cherrypicked',
                       barcode: 'DN1' }
    expect(presenter.label.attributes).to eq(expected_label)
  end

  it 'returns PlateDoubleLabel attributes when PlateDoubleLabel is defined in the purpose settings' do
    Settings.purposes[labware.purpose.uuid] = build(:purpose_config, label_class: 'Labels::PlateDoubleLabel')
    expected_label = {
      attributes: { right_text: 'DN2',
                    left_text: 'DN 1',
                    barcode: '1220000001831' },
      extra_attributes: { right_text: 'DN2 Limber Cherrypicked',
                          left_text: Time.zone.today.strftime('%e-%^b-%Y') }
    }
    actual_label = {
      attributes: presenter.label.attributes,
      extra_attributes: presenter.label.extra_attributes
    }
    expect(actual_label).to eq(expected_label)
  end

  it_behaves_like 'a labware presenter'

  context 'a plate with conflicting pools' do
    let(:labware) do
      build :plate, pool_sizes: [2, 2], pool_prc_cycles: [10, 6]
    end

    it 'reports as invalid' do
      expect(presenter).to_not be_valid
    end

    it 'reports the error' do
      presenter.valid?
      expect(presenter.errors.full_messages).to include('Pcr cycles specified is not consistent across the plate.')
    end
  end

  context 'where the cycles differs from the default' do
    before(:each) do
      Settings.purposes[labware.purpose.uuid] ||= {}
      Settings.purposes[labware.purpose.uuid]['warnings'] = { 'pcr_cycles_not_in' => ['6'] }
    end

    it 'reports as invalid' do
      expect(presenter).to_not be_valid
    end

    it 'reports the error' do
      presenter.valid?
      expect(presenter.errors.full_messages).to include('Pcr cycles differs from standard. 10 cycles have been requested.')
    end
  end

  context 'where the cycles matches the default' do
    before(:each) do
      Settings.purposes[labware.purpose.uuid] ||= {}
      Settings.purposes[labware.purpose.uuid]['warnings'] = { 'pcr_cycles_not_in' => ['10'] }
    end

    it 'reports as valid' do
      expect(presenter).to be_valid
    end
  end

  context 'where no default is specified' do
    before(:each) do
      Settings.purposes[labware.purpose.uuid] ||= {}
      Settings.purposes[labware.purpose.uuid]['warnings'] = {}
    end

    it 'reports as valid' do
      expect(presenter).to be_valid
    end
  end
end
