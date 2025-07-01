# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Presenters::Presenter, type: :model do
  # Presenter is a module so we need a dummy class
  let(:dummy_class) { Class.new { include Presenters::Presenter } }

  let(:presenter) { dummy_class.new }

  describe '#parent_labwares' do
    context 'when there are no parents' do
      before { allow(presenter.labware).to receive(:parents).and_return([]) }

      it 'returns an empty array' do
        expect(presenter.parent_labwares).to eq([])
      end
    end

    context 'when there are parents' do
      let(:parent_labware) { create(:labware) }

      before do
        allow(presenter.labware).to receive(:parents).and_return([parent_labware])
        allow(Sequencescape::Api::V2::Labware).to receive(:find_all).with(
          { uuid: [parent_labware.uuid] },
          includes: %w[purpose]
        ).and_return([parent_labware])
      end

      it 'returns the parent labwares with purposes' do
        expect(presenter.parent_labwares).to eq([parent_labware])
      end
    end
  end

  describe '#show_pooling_tab?' do
    context 'when pooling_tab in the presenter has a value' do
      before { presenter.pooling_tab = 'some_value' }

      it 'returns true' do
        expect(presenter.show_pooling_tab?).to be true
      end
    end

    context 'when pooling_tab in the presenter has no value' do
      before { presenter.pooling_tab = '' }

      it 'returns false' do
        expect(presenter.show_pooling_tab?).to be false
      end
    end
  end
end
