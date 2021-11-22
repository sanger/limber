# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::TubeRackLabel, type: :model do
  it { expect(described_class).to be < Labels::Base }

  context 'when creating the label of a plate' do
    let(:labware) { create :tube_rack, barcode_number: 2 }
    let(:label) { described_class.new(labware) }

    context '#attributes' do
      it 'has the correct attributes' do
        attributes = label.attributes
        expect(attributes[:top_left]).to eq Time.zone.today.strftime('%e-%^b-%Y')
        expect(attributes[:bottom_left]).to eq 'DN2T'
        expect(attributes[:top_right]).to eq labware.name
        expect(attributes[:bottom_right]).to eq labware.purpose_name
        expect(attributes[:barcode]).to eq labware.barcode.machine
      end
    end
  end
end
