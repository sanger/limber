# frozen_string_literal: true

require 'rails_helper'
require 'presenters/tube_presenter'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::TubePresenter do
  has_a_working_api

  let(:labware) do
    build :v2_multiplexed_library_tube,
          receptacle: receptacle,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 6,
          created_at: '2016-10-19 12:00:00 +0100'
  end

  before do
    create(:stock_plate_config, uuid: 'stock-plate-purpose-uuid')
  end

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:qc_results) do
    [
      create(:qc_result, key: 'volume', value: '600.0', units: 'ul'),
      create(:qc_result, key: 'molarity', value: '5.5', units: 'nM')
    ]
  end
  let(:receptacle) { create :v2_receptacle, qc_results: qc_results }
  let(:summary_tab) do
    [
      ['Barcode', 'NT6T <em>3980000006844</em>'],
      ['Tube type', purpose_name],
      ['Current tube state', state],
      ['Input plate barcode', 'DN2T'],
      ['Created on', '2016-10-19']
    ]
  end
  let(:sidebar_partial) { 'default' }

  subject do
    Presenters::TubePresenter.new(
      api: api,
      labware: labware
    )
  end

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
    context 'no qc results' do
      let(:qc_results) { [] }
      it_behaves_like 'no qc summary'
    end

    context 'two qc results' do
      it_behaves_like 'qc summary'

      it 'yields all the summary items in alphabetical order' do
        expect { |b| subject.qc_summary(&b) }.to yield_successive_args(['Molarity', '5.5 nM'], ['Volume', '600 ul'])
      end
    end
  end
end
