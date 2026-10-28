# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::TubeLabel, type: :model do
  it { expect(described_class).to be < Labels::Base }

  context 'when creating the label of a plate' do
    let(:labware) { create :tube }
    let(:label) { described_class.new(labware) }

    describe '#attributes' do
      it 'has the correct attributes' do
        attributes = label.attributes
        expect(attributes[:first_line]).to eq labware.name[2..] if labware.name.present?
        expect(attributes[:second_line]).to include(', P')
        expect(attributes[:third_line]).to eq labware.purpose.name
        expect(attributes[:fourth_line]).to eq Time.zone.today.strftime('%e-%^b-%Y')
        expect(attributes[:round_label_top_line]).to eq labware.barcode.prefix
        expect(attributes[:round_label_bottom_line]).to eq labware.barcode.number
        expect(attributes[:barcode]).to eq labware.barcode.ean13
      end
    end
  end

  # Its only barcode is an external one without a number, as Sapio
  # reception creates (Y26-283)
  context 'when the tube barcode has no number' do
    let(:labware) do
      create :tube, labware_barcode: { 'ean13_barcode' => nil,
                                       'human_barcode' => 'SAPIO-TUBE',
                                       'machine_barcode' => 'SAPIO-TUBE' }
    end

    it 'shows the whole barcode in place of its number' do
      expect(described_class.new(labware).attributes).to include(
        second_line: start_with('SAPIO-TUBE, P'),
        round_label_top_line: nil,
        round_label_bottom_line: 'SAPIO-TUBE'
      )
    end
  end
end
