# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::TubeLabelKinnex do
  it { expect(described_class).to be < Labels::Base }

  context 'when printing from tube presenter' do
    let(:labware) { create(:tube, name: 'ABCD:A1') }
    let(:label) { described_class.new(labware) }

    before do
      allow(labware).to receive(:transfer_requests_as_target).and_return(
        [create(:transfer_request, source_asset: labware)]
      )
      allow(label).to receive(:labware_with_includes).and_return(labware)
    end

    describe '#attributes' do
      let(:attributes) { label.attributes }

      it 'has the correct fourth_line attribute' do
        expect(attributes[:fourth_line]).to eq Time.zone.today.strftime('%e-%^b-%Y')
      end

      it 'has the correct first_line attribute' do
        expect(attributes[:first_line]).to eq labware.barcode.human
      end

      it 'has the correct second_line attribute' do
        expect(attributes[:second_line]).to eq 'ABCD:A1'
      end

      it 'has the correct third_line attribute' do
        expect(attributes[:third_line]).to eq labware.purpose_name
      end

      it 'has the correct round_label_top_line attribute' do
        expect(attributes[:round_label_top_line]).to eq labware.barcode.prefix
      end

      it 'has the correct round_label_bottom_line attribute' do
        expect(attributes[:round_label_bottom_line]).to eq labware.barcode.number
      end

      it 'has the correct barcode attribute' do
        expect(attributes[:barcode]).to eq labware.barcode.human
      end
    end
  end
end
