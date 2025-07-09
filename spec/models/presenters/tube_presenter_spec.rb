# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::TubePresenter do
  subject { described_class.new(labware:) }

  let(:labware) do
    build :v2_tube,
          receptacle: receptacle,
          purpose: purpose,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 6,
          created_at: '2016-10-19 12:00:00 +0100'
  end

  let!(:purpose_config) { create(:stock_plate_config, uuid: purpose_uuid) }
  let(:purpose) { create :v2_purpose, name: purpose_name, uuid: purpose_uuid }
  let(:purpose_name) { 'Limber example purpose' }
  let(:purpose_uuid) { 'example-purpose-uuid' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:qc_results) do
    [
      create(:qc_result, key: 'volume', value: '600.0', units: 'ul'),
      create(:qc_result, key: 'molarity', value: '5.5', units: 'nM')
    ]
  end
  let(:receptacle) { create :v2_receptacle, qc_results: }
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

  shared_examples 'qc summary' do
    it 'has a qc_summary' do
      expect(subject.qc_summary?).to be_truthy
    end
  end

  shared_examples 'no qc summary' do
    it 'has no qc_summary' do
      expect(subject.qc_summary?).to be_falsey
    end
  end

  context 'has no receptacle' do
    let(:receptacle) { nil }

    it_behaves_like 'no qc summary'
  end

  context 'has a receptacle' do
    let!(:purpose_config) { create(:tube_with_transfer_parameters_config, uuid: purpose_uuid) }

    context 'no qc results' do
      let(:qc_results) { [] }

      it_behaves_like 'no qc summary'
    end

    context 'two qc results' do
      it_behaves_like 'qc summary'

      it 'yields all the summary items in alphabetical order' do
        expect { |b| subject.qc_summary(&b) }.to yield_successive_args(['Molarity', '5.5 nM'], ['Volume', '600 ul'])
      end

      it 'has transfer volumes' do
        expect(subject.transfer_volumes?).to be_truthy
      end
    end

    context 'missing transfer_parameters' do
      let!(:purpose_config) do
        create(:tube_with_transfer_parameters_config, uuid: purpose_uuid, transfer_parameters: nil)
      end

      it 'does not have transfer volumes' do
        expect(subject.transfer_volumes?).to be_falsey
      end
    end
  end

  describe '#custom_metadata_fields' do
    context 'with custom_metadata_fields' do
      before { create(:plate_with_custom_metadata_fields_config) }

      it 'returns a JSON string with a array of custom_metadata_fields config' do
        expect(subject.custom_metadata_fields).to eq('["IDX DFD Syringe lot Number","Another"]')
      end
    end

    context 'with empty custom_metadata_fields' do
      before { create(:plate_with_empty_custom_metadata_fields_config) }

      it 'returns a JSON string with a empty object when no custom_metadata_fields config exists' do
        expect(subject.custom_metadata_fields).to eq('[]')
      end
    end

    context 'without custom_metadata_fields' do
      it 'returns a JSON string with a empty object when no custom_metadata_fields config exists' do
        expect(subject.custom_metadata_fields).to eq('[]')
      end
    end
  end

  describe '#csv_links_for' do
    let!(:purpose_config) { create(:tube_with_file_links_config, uuid: purpose_uuid) }

    context 'when the file is a .tsv' do
      it 'renders the right links' do
        expect(subject.csv_file_links).to eq(
          [
            [
              'Download MBrave UMI file',
              [:tube, :tubes_export, { id: 'bioscan_mbrave', tube_id: 'NT6T', format: 'tsv' }]
            ]
          ]
        )
      end
    end
  end
end
