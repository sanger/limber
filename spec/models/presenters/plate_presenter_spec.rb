# frozen_string_literal: true

require 'rails_helper'
require 'presenters/plate_presenter'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::PlatePresenter do
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
    build :v2_plate,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 1,
          pool_sizes: [48, 48],
          created_at: '2016-10-19 12:00:00 +0100'
  end

  let(:warnings) { {} }
  let(:label_class) { 'Labels::PlateLabel' }

  before do
    create(:purpose_config, uuid: labware.purpose.uuid, warnings: warnings, label_class: label_class)
    create(:stock_plate_config, uuid: 'stock-plate-purpose-uuid')
  end

  subject(:presenter) do
    Presenters::PlatePresenter.new(
      api:     api,
      labware: labware
    )
  end

  context 'with the default label class "Labels::PlateLabel"' do
    it 'returns PlateLabel attributes when PlateLabel is defined in the purpose settings' do
      expected_label = { top_left: Time.zone.today.strftime('%e-%^b-%Y'),
                         bottom_left: 'DN1S',
                         top_right: 'DN2T',
                         bottom_right: "WGS #{purpose_name}",
                         barcode: '1220000001831' }
      expect(presenter.label.attributes).to eq(expected_label)
    end
  end

  context 'when PlateDoubleLabel is defined in the purpose settings' do
    let(:label_class) { 'Labels::PlateDoubleLabel' }

    it 'returns PlateDoubleLabel attributes when PlateDoubleLabel is defined in the purpose settings' do
      expected_label = {
        attributes: { right_text: 'DN2T',
                      left_text: 'DN1S',
                      barcode: '1220000001831' },
        extra_attributes: { right_text: "DN2T WGS #{purpose_name}",
                            left_text: Time.zone.today.strftime('%e-%^b-%Y') }
      }
      actual_label = {
        attributes: presenter.label.attributes,
        extra_attributes: presenter.label.extra_attributes
      }
      expect(actual_label).to eq(expected_label)
    end
  end

  it_behaves_like 'a labware presenter'

  describe '#pools' do
    let(:labware) { create :v2_plate, pool_sizes: [2, 2], pool_prc_cycles: [10, 6] }
    it 'returns a pool per submission' do
      expect(presenter.pools).to be_a Sequencescape::Api::V2::Plate::Pools
      expect(presenter.pools.number_of_pools).to eq(2)
      expect { |b| presenter.pools.each(&b) }.to yield_control.twice
    end
  end

  context 'a plate with conflicting pools' do
    let(:labware) { create :v2_plate, pool_sizes: [2, 2], pool_prc_cycles: [10, 6] }

    it 'reports as invalid' do
      expect(presenter).to_not be_valid
    end

    it 'reports the error' do
      presenter.valid?
      expect(presenter.errors.full_messages).to include('Pcr cycles specified is not consistent across the plate.')
    end
  end

  context 'where the cycles differs from the default' do
    let(:warnings) { { 'pcr_cycles_not_in' => ['6'] } }

    it 'reports as invalid' do
      expect(presenter).to_not be_valid
    end

    it 'reports the error' do
      presenter.valid?
      expect(presenter.errors.full_messages).to include('Pcr cycles differs from standard. 10 cycles have been requested.')
    end
  end

  context 'where the cycles matches the default' do
    let(:warings) { { 'pcr_cycles_not_in' => ['10'] } }

    it 'reports as valid' do
      expect(presenter).to be_valid
    end
  end

  context 'where no default is specified' do
    it 'reports as valid' do
      expect(presenter).to be_valid
    end
  end

  context 'with tubes' do
    # Due to limitations in polymorphic associations in the json-client-api gem
    # we actually get assets back. But we can check their type
    let(:target_tube) { create :v2_asset_tube }
    let(:target_tube2) { create :v2_asset_tube }

    let(:labware) do
      create :v2_plate, uuid: 'plate-uuid', transfer_targets: {
        'A1' => [target_tube], 'B1' => [target_tube], 'C1' => [target_tube2]
      }
    end

    it 'returns the correct number of labels' do
      expect(subject.tube_labels.length).to eq 2
    end

    it 'can return the tubes and sources' do
      expect(subject.tubes_and_sources.map(&:tube)).to eq([target_tube, target_tube2])
      expect(subject.tubes_and_sources.map(&:source_locations)).to eq([%w[A1 B1], ['C1']])
    end
  end
end
