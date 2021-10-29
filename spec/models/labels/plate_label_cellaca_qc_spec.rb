# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::PlateLabelCellacaQc, type: :model do
  it { expect(described_class).to be < Labels::Base }

  describe '#attributes' do
    subject(:qc_attributes) { label.qc_attributes }
    let(:label) { described_class.new(labware) }

    context 'when creating the label of a full plate' do
      let(:labware) { create :v2_plate, pool_sizes: [96] }

      it 'contains four items' do
        expect(qc_attributes.length).to eq(4)
      end
    end

    context 'when creating the label of a partial plate' do
      let(:labware) { create :v2_plate, pool_sizes: [5] }

      it 'contains four items' do
        expect(qc_attributes.length).to eq(1)
      end
    end
  end
end
