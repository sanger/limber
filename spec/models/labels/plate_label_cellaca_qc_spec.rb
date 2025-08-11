# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::PlateLabelCellacaQc, type: :model do
  it { expect(described_class).to be < Labels::Base }

  describe '#attributes' do
    subject(:attributes) { label.attributes }

    let(:labware) { create :plate, barcode_number: 2 }
    let(:label) { described_class.new(labware) }

    it 'has the additional attributes' do
      expect(attributes[:barcode]).to eq labware.barcode.human
    end
  end

  describe '#qc_label_definitions' do
    subject(:qc_label_definitions) { label.qc_label_definitions }

    let(:label) { described_class.new(labware) }

    context 'when creating the label of a full plate' do
      let(:labware) { create :plate, pool_sizes: [96] }

      it 'contains four items' do
        expect(qc_label_definitions.length).to eq(4)

        expect(qc_label_definitions.pluck(:top_left)).to all(eq(Time.zone.today.strftime('%e-%^b-%Y')))
        expect(qc_label_definitions.pluck(:top_right)).to all(eq('DN2T'))
        expect(qc_label_definitions.pluck(:bottom_left)).to eq(
          [
            "#{labware.barcode.human} QC4",
            "#{labware.barcode.human} QC3",
            "#{labware.barcode.human} QC2",
            "#{labware.barcode.human} QC1"
          ]
        )
        expect(qc_label_definitions.pluck(:barcode)).to eq(
          [
            "#{labware.barcode.human}-QC4",
            "#{labware.barcode.human}-QC3",
            "#{labware.barcode.human}-QC2",
            "#{labware.barcode.human}-QC1"
          ]
        )
      end
    end

    context 'when creating the label of a partial plate' do
      let(:labware) { create :plate, pool_sizes: [5] }

      it 'contains four items' do
        expect(qc_label_definitions.length).to eq(1)
        expect(qc_label_definitions.pluck(:barcode)).to eq(["#{labware.barcode.human}-QC1"])
      end
    end
  end
end
