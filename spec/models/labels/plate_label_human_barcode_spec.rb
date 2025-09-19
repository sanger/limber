# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::PlateLabelHumanBarcode, type: :model do
  it { expect(described_class).to be < Labels::Base }

  context 'when creating the label of a plate with a human readable barcode' do
    let(:labware) { create :plate }
    let(:label) { described_class.new(labware) }

    describe '#attributes' do
      it 'has the correct attributes' do
        attributes = label.attributes
        expect(attributes[:top_left]).to eq Time.zone.today.strftime('%e-%^b-%Y')
        expect(attributes[:bottom_left]).to eq labware.barcode.human
        expect(attributes[:top_right]).to eq labware.workline_identifier
        expect(attributes[:bottom_right]).to eq [labware.role, labware.purpose.name].compact.join(' ')
        expect(attributes[:barcode]).to eq labware.barcode.human
      end
    end
  end
end
