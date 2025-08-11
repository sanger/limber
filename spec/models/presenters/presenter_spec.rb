# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Presenters::Presenter, type: :model do
  # Presenter is a module so we need a dummy class
  let(:dummy_class) { Class.new { include Presenters::Presenter } }

  let(:labware) { create :plate }
  let(:presenter) { dummy_class.new(labware:) }

  describe '#parent_labwares' do
    let(:parent_labware_uuids) { (parent_labwares || []).map(&:uuid) }

    before do
      allow(presenter.labware).to receive(:parents).and_return(parent_labwares)
      allow(Sequencescape::Api::V2::Labware).to receive(:find_all).with(
        { uuid: parent_labware_uuids },
        includes: %w[purpose]
      ).and_return(parent_labwares)
    end

    context 'when there are no parents' do
      let(:parent_labwares) { nil }

      it 'returns an empty array' do
        expect(presenter.parent_labwares).to eq([])
      end
    end

    context 'when there are parents' do
      let(:purpose) { create(:purpose) }
      let(:parent_labware1) { create(:labware, purpose:) }
      let(:parent_labware2) { create(:labware, purpose:) }
      let(:parent_labwares) { [parent_labware1, parent_labware2] }

      it 'returns the parent labwares' do
        expect(presenter.parent_labwares).to eq([parent_labware1, parent_labware2])
      end

      context 'where some parents do not have a purpose' do
        let(:parent_labware3) { create(:labware, purpose: nil) }
        let(:parent_labwares) { [parent_labware1, parent_labware2, parent_labware3] }

        it 'returns only the parents with a purpose' do
          expect(presenter.parent_labwares).to eq([parent_labware1, parent_labware2])
        end
      end
    end
  end

  describe '#child_labwares' do
    let(:child_labware_uuids) { (child_labwares || []).map(&:uuid) }

    before do
      allow(presenter.labware).to receive(:children).and_return(child_labwares)
      allow(Sequencescape::Api::V2::Labware).to receive(:find_all).with(
        { uuid: child_labware_uuids },
        includes: %w[purpose]
      ).and_return(child_labwares)
    end

    context 'when there are no children' do
      let(:child_labwares) { nil }

      it 'returns an empty array' do
        expect(presenter.child_labwares).to eq([])
      end
    end

    context 'when there are children' do
      let(:purpose) { create(:purpose) }
      let(:child_labware1) { create(:labware, purpose:) }
      let(:child_labware2) { create(:labware, purpose:) }
      let(:child_labwares) { [child_labware1, child_labware2] }

      it 'returns the child labwares' do
        expect(presenter.child_labwares).to eq([child_labware1, child_labware2])
      end

      context 'where some children do not have a purpose' do
        let(:child_labware3) { create(:labware, purpose: nil) }
        let(:child_labwares) { [child_labware1, child_labware2, child_labware3] }

        it 'returns only the children with a purpose' do
          expect(presenter.child_labwares).to eq([child_labware1, child_labware2])
        end
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
