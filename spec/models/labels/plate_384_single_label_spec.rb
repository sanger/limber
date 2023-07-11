# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::Plate384SingleLabel, type: :model do
  it { expect(described_class).to be < Labels::Base }

  context 'when creating the label of a plate' do
    let(:labware) { build :v2_plate, purpose_name: 'LBSN-384 PCR 1', size: 384 }
    let(:label) { Labels::Plate384SingleLabel.new(labware) }
    let(:date_format) { /\A\s?\d{1,2}-[A-Z]{3}-\d{4}\z/ } # e.g., ' 4 JUL 2023' or '24 JUL 2023'

    before do
      create :stock_plate_config
      allow(label).to receive(:first_of_last_purpose).and_return(labware.stock_plate)
    end

    context '#attributes' do
      it 'has the correct attributes' do
        attributes = label.attributes
        expect(attributes[:top_left]).to match(date_format)
        expect(attributes[:bottom_left]).to eq labware.barcode.human
        expect(attributes[:top_right]).to eq labware.workline_identifier
        expect(attributes[:bottom_right]).to eq labware.purpose_name
        expect(attributes[:barcode]).to eq labware.barcode.human
      end
    end

    context '#sprint_attributes' do
      it 'has the correct attributes' do
        attributes = label.sprint_attributes
        expect(attributes[:top_left]).to match(date_format)
        expect(attributes[:bottom_left]).to eq(labware.barcode.human)
        expect(attributes[:top_right]).to eq labware.workline_identifier
        expect(attributes[:bottom_right]).to eq labware.purpose_name
        expect(attributes[:barcode]).to eq labware.barcode.human
      end
    end
  end
end
