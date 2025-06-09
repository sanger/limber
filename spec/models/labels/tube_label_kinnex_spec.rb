# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::TubeLabelKinnex do
  it { expect(described_class).to be < Labels::Base }

  context 'when printing from tube presenter' do
    let(:labware) { create(:v2_tube, name: 'ABCD:A1') }
    let(:label) { described_class.new(labware) }

    before do
      allow(labware).to receive(:transfer_requests_as_target).and_return(
        [create(:v2_transfer_request, source_asset: labware)]
      )
    end

    describe '#attributes' do
      let(:attributes) { label.attributes }

      it 'has the correct top_left attribute' do
        expect(attributes[:top_left]).to eq Time.zone.today.strftime('%e-%^b-%Y')
      end

      it 'has the correct bottom_left attribute' do
        expect(attributes[:bottom_left]).to eq labware.barcode.human
      end

      it 'has the correct top_right attribute' do
        expect(attributes[:top_right]).to eq 'ABCD:A1'
      end

      it 'has the correct bottom_right attribute' do
        expect(attributes[:bottom_right]).to eq 'WGS example-purpose'
      end

      it 'has the correct barcode attribute' do
        expect(attributes[:barcode]).to eq labware.barcode.human
      end
    end
  end
end
