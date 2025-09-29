# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::PlateDoubleLabel, type: :model do
  it { expect(described_class).to be < Labels::Base }

  context 'when creating the label of a plate' do
    let(:labware) { create :plate }
    let(:label) { described_class.new(labware) }

    describe '#attributes' do
      it 'has the correct attributes' do
        attributes = label.attributes
        expect(attributes[:right_text]).to eq labware.workline_identifier
        expect(attributes[:left_text]).to eq labware.barcode.human
        expect(attributes[:barcode]).to eq labware.barcode.machine
      end
    end

    describe '#extra_attributes' do
      it 'has the correct attributes' do
        extra_attributes = label.extra_attributes
        expect(
          extra_attributes[:right_text]
        ).to eq "#{labware.workline_identifier} #{labware.role} #{labware.purpose.name}"
        expect(extra_attributes[:left_text]).to eq Time.zone.today.strftime('%e-%^b-%Y')
      end
    end

    describe '#sprint_attributes' do
      it 'has the correct attributes' do
        sprint_attributes = label.sprint_attributes
        expect(sprint_attributes[:right_text]).to eq labware.workline_identifier
        expect(sprint_attributes[:left_text]).to eq labware.barcode.human
        expect(sprint_attributes[:barcode]).to eq labware.barcode.machine
        expect(
          sprint_attributes[:extra_right_text]
        ).to eq "#{labware.workline_identifier} #{labware.role} #{labware.purpose.name}"
        expect(sprint_attributes[:extra_left_text]).to eq Time.zone.today.strftime('%e-%^b-%Y')
      end
    end
  end
end
