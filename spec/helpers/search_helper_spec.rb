# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  context '#alternative_workline_reference_name' do
    let(:plate) { double('plate') }
    before do
      allow(Settings.pipelines).to receive(:active_pipelines_for).with(plate).and_return(pipelines)
    end
    context 'when no pipelines are found for the labware' do
      let(:pipelines) { [] }
      it 'returns nil' do
        expect(SearchHelper.alternative_workline_reference_name(plate)).to be_nil
      end
    end
    context 'when one or more pipelines are found' do
      let(:p1) { build(:pipeline, alternative_workline_identifier: refer1) }
      let(:p2) { build(:pipeline, alternative_workline_identifier: refer2) }
      let(:pipelines) { [p1, p2] }
      context 'when no references are found in any pipeline' do
        let(:refer1) { nil }
        let(:refer2) { nil }
        it 'returns nil' do
          expect(SearchHelper.alternative_workline_reference_name(plate)).to be_nil
        end
      end
      context 'when the same workline reference name is found' do
        let(:refer1) { 'same' }
        let(:refer2) { 'same' }
        it 'returns that reference' do
          expect(SearchHelper.alternative_workline_reference_name(plate)).to eq('same')
        end
      end
      context 'when different workline references are found' do
        let(:refer1) { 'same' }
        let(:refer2) { 'different' }
        it 'returns nil' do
          expect(SearchHelper.alternative_workline_reference_name(plate)).to be_nil
        end
      end
    end
  end
end
