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
        expect(attributes[:second_line]).to match(/, P/)
        expect(attributes[:third_line]).to eq labware.purpose.name
        expect(attributes[:fourth_line]).to eq Time.zone.today.strftime('%e-%^b-%Y')
        expect(attributes[:round_label_top_line]).to eq labware.barcode.prefix
        expect(attributes[:round_label_bottom_line]).to eq labware.barcode.number
        expect(attributes[:barcode]).to eq labware.barcode.ean13
      end
    end
  end
end
