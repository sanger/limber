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
      %w[Barcode DN1S],
      ['Number of wells', '96/96'],
      ['Plate type', purpose_name],
      ['Current plate state', state],
      ['Input plate barcode', 'DN2T'],
      ['PCR Cycles', '10'],
      ['Created on', '2016-10-19']
    ]
  end
  let(:sidebar_partial) { 'default' }

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

  subject(:presenter) { Presenters::PlatePresenter.new(api: api, labware: labware) }

  context 'with the default label class "Labels::PlateLabel"' do
    it 'returns PlateLabel attributes when PlateLabel is defined in the purpose settings' do
      expected_label = {
        top_left: Time.zone.today.strftime('%e-%^b-%Y'),
        bottom_left: 'DN1S',
        top_right: 'DN2T',
        bottom_right: "WGS #{purpose_name}",
        barcode: 'DN1S'
      }
      expect(presenter.label.attributes).to eq(expected_label)
    end
  end

  context 'when PlateDoubleLabel is defined in the purpose settings' do
    let(:label_class) { 'Labels::PlateDoubleLabel' }

    it 'returns PlateDoubleLabel attributes when PlateDoubleLabel is defined in the purpose settings' do
      expected_label = {
        attributes: {
          right_text: 'DN2T',
          left_text: 'DN1S',
          barcode: 'DN1S'
        },
        extra_attributes: {
          right_text: "DN2T WGS #{purpose_name}",
          left_text: Time.zone.today.strftime('%e-%^b-%Y')
        }
      }
      actual_label = { attributes: presenter.label.attributes, extra_attributes: presenter.label.extra_attributes }
      expect(actual_label).to eq(expected_label)
    end
  end

  context 'when PlateDoubleLabelQc is defined in the purpose settings' do
    let(:label_class) { 'Labels::PlateDoubleLabelQc' }

    it 'returns PlateDoubleLabelQc attributes when PlateDoubleLabelQc is defined in the purpose settings' do
      expected_label = {
        attributes: {
          right_text: 'DN2T',
          left_text: 'DN1S',
          barcode: 'DN1S'
        },
        extra_attributes: {
          right_text: "DN2T WGS #{purpose_name}",
          left_text: Time.zone.today.strftime('%e-%^b-%Y')
        },
        qc_attributes: [
          { right_text: 'DN2T', left_text: 'DN1S QC', barcode: 'DN1S-QC' },
          { right_text: "DN2T WGS #{purpose_name} QC", left_text: Time.zone.today.strftime('%e-%^b-%Y') }
        ]
      }
      actual_label = {
        attributes: presenter.label.attributes,
        extra_attributes: presenter.label.extra_attributes,
        qc_attributes: presenter.label.qc_attributes
      }
      expect(actual_label).to eq(expected_label)
    end
  end

  context 'when PlateLabelXP is defined in the purpose settings' do
    let(:label_class) { 'Labels::PlateLabelXp' }

    it 'returns PlateLabelXP attributes when PlateLabelXP is defined in the purpose settings' do
      expected_label = {
        top_left: Time.zone.today.strftime('%e-%^b-%Y'),
        bottom_left: 'DN1S',
        top_right: 'DN2T',
        bottom_right: "WGS #{purpose_name}",
        barcode: 'DN1S'
      }
      expect(presenter.label.attributes).to eq(expected_label)
      expected_qc_attributes = [
        {
          top_left: Time.zone.today.strftime('%e-%^b-%Y'),
          bottom_left: 'DN1S QC',
          top_right: 'DN2T',
          barcode: 'DN1S-QC'
        }
      ]
      expect(presenter.label.qc_attributes).to eq(expected_qc_attributes)
    end
  end

  context 'when PlateLabelLdsAlLib is defined in the purpose settings' do
    let(:label_class) { 'Labels::PlateLabelLdsAlLib' }

    it 'returns PlateLabelLdsAlLib attributes when PlateLabelLdsAlLib is defined in the purpose settings' do
      expected_label = {
        top_left: Time.zone.today.strftime('%e-%^b-%Y'),
        bottom_left: 'DN1S',
        top_right: 'DN2T',
        bottom_right: "WGS #{purpose_name}",
        barcode: 'DN1S'
      }
      expect(presenter.label.attributes).to eq(expected_label)
      expected_intermediate_attributes = [
        {
          top_left: Time.zone.today.strftime('%e-%^b-%Y'),
          bottom_left: 'DN1S',
          top_right: 'DN2T',
          bottom_right: 'WGS LDS Lig',
          barcode: 'DN1S-LIG'
        },
        {
          top_left: Time.zone.today.strftime('%e-%^b-%Y'),
          bottom_left: 'DN1S',
          top_right: 'DN2T',
          bottom_right: 'WGS LDS A-tail',
          barcode: 'DN1S-ATL'
        },
        {
          top_left: Time.zone.today.strftime('%e-%^b-%Y'),
          bottom_left: 'DN1S',
          top_right: 'DN2T',
          bottom_right: 'WGS LDS Frag',
          barcode: 'DN1S-FRG'
        }
      ]
      expected_qc_attributes = [
        {
          top_left: Time.zone.today.strftime('%e-%^b-%Y'),
          bottom_left: 'DN1S QC3',
          top_right: 'DN2T',
          barcode: 'DN1S-QC3'
        },
        {
          top_left: Time.zone.today.strftime('%e-%^b-%Y'),
          bottom_left: 'DN1S QC2',
          top_right: 'DN2T',
          barcode: 'DN1S-QC2'
        },
        {
          top_left: Time.zone.today.strftime('%e-%^b-%Y'),
          bottom_left: 'DN1S QC1',
          top_right: 'DN2T',
          barcode: 'DN1S-QC1'
        }
      ]
      expect(presenter.label.qc_attributes).to eq(expected_qc_attributes)
      expect(presenter.label.intermediate_attributes).to eq(expected_intermediate_attributes)
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
      expect(presenter.errors.full_messages).to include('Pcr cycles are not consistent across the plate.')
    end
  end

  context 'a plate with conflicting but overlapping pools' do
    # In the GnT pipeline we have two requests out of the stock plates, which will be
    # split up onto different plates. They have different PCR cycle requirements, but
    # the warning is not required and is unwanted. This check disables the warning
    # if the plate contains split processes
    let(:labware) { create :v2_plate, barcode_number: '2', wells: wells }
    let(:request_a) { create :library_request, pcr_cycles: 1 }
    let(:request_b) { create :library_request, pcr_cycles: 2 }
    let(:request_c) { create :library_request, pcr_cycles: 1 }
    let(:request_d) { create :library_request, pcr_cycles: 2 }
    let(:wells) do
      [
        create(
          :v2_stock_well,
          uuid: '2-well-A1',
          location: 'A1',
          aliquot_count: 1,
          requests_as_source: [request_a, request_b]
        ),
        create(
          :v2_stock_well,
          uuid: '2-well-B1',
          location: 'B1',
          aliquot_count: 1,
          requests_as_source: [request_c, request_d]
        )
      ]
    end

    it 'reports as valid' do
      expect(presenter).to be_valid
    end
  end

  context 'where the cycles differs from the default' do
    let(:warnings) { { 'pcr_cycles_not_in' => ['6'] } }

    it 'reports as invalid' do
      expect(presenter).to_not be_valid
    end

    it 'reports the error' do
      presenter.valid?
      expect(presenter.errors.full_messages).to include(
        'Requested pcr cycles differs from standard. 10 cycles have been requested.'
      )
    end
  end

  context 'where the cycles matches the default' do
    let(:warnings) { { 'pcr_cycles_not_in' => ['10'] } }

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
      create :v2_plate,
             uuid: 'plate-uuid',
             transfer_targets: {
               'A1' => [target_tube],
               'B1' => [target_tube],
               'C1' => [target_tube2]
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

  context 'returns csv links ' do
    context 'with a default plate' do
      let(:expected_default_csv_links) do
        [
          [
            'Download Concentration CSV',
            [:limber_plate, :export, { format: :csv, id: 'concentrations', limber_plate_id: 'DN1S' }]
          ]
        ]
      end

      it 'returns the expected csv links' do
        expect(presenter.csv_file_links).to eq(expected_default_csv_links)
      end
    end

    context 'with a plate that has no links' do
      before do
        create(
          :purpose_config,
          uuid: labware.purpose.uuid,
          warnings: warnings,
          label_class: label_class,
          file_links: []
        )
      end

      it 'returns an empty array' do
        expect(presenter.csv_file_links).to eq([])
      end
    end

    context 'with a plate that has multiple links' do
      before do
        create(
          :purpose_config,
          uuid: labware.purpose.uuid,
          warnings: warnings,
          label_class: label_class,
          file_links: [
            { name: 'First type CSV', id: 'first_csv_id' },
            { name: 'Second type CSV', id: 'second_csv_id' },
            { name: 'Third type CSV', id: 'third_csv_id' }
          ]
        )
      end

      it 'returns the expected number of links' do
        expect(presenter.csv_file_links.length).to eq(3)
      end
    end

    context 'with a plate with additional parameters' do
      before do
        create(
          :purpose_config,
          uuid: labware.purpose.uuid,
          warnings: warnings,
          label_class: label_class,
          file_links: [
            { name: 'Button 1', id: 'template', params: { page: 0 } },
            { name: 'Button 2', id: 'template', params: { page: 1 } }
          ]
        )
      end

      it 'returns the expected number of links' do
        expect(presenter.csv_file_links).to eq(
          [
            [
              'Button 1',
              [:limber_plate, :export, { :format => :csv, :id => 'template', :limber_plate_id => 'DN1S', 'page' => 0 }]
            ],
            [
              'Button 2',
              [:limber_plate, :export, { :format => :csv, :id => 'template', :limber_plate_id => 'DN1S', 'page' => 1 }]
            ]
          ]
        )
      end
    end
  end
end
