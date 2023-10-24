# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::TubeLabelTractionCompatible, type: :model do
  it { expect(described_class).to be < Labels::Base }

  let(:labware) { build :v2_tube, parents: [build(:v2_tube)] }
  let(:label) { described_class.new(labware) }
  let(:date_format) { /\A\s?\d{1,2}-[A-Z]{3}-\d{4}\z/ } # e.g., ' 4 JUL 2023' or '24 JUL 2023'

  context 'when creating the label of a tube' do
    it 'has the correct attributes' do
      attributes = label.attributes
      expect(attributes[:first_line]).to eq labware.parents[0].barcode.human
      expect(attributes[:second_line]).to match(/, P/)
      expect(attributes[:third_line]).to eq labware.purpose.name
      expect(attributes[:fourth_line]).to eq Time.zone.today.strftime('%e-%^b-%Y')
      expect(attributes[:round_label_top_line]).to eq labware.barcode.prefix
      expect(attributes[:round_label_bottom_line]).to eq labware.barcode.human[2..]
      expect(attributes[:barcode]).to eq labware.barcode.human
    end
  end

  context 'when labware name contains plate and well range' do
    let(:labware) { build :v2_tube, name: 'SQPT-12345-H A1:P24', parents: [build(:v2_tube)] }

    it 'has the correct attributes' do
      attributes = label.attributes
      expect(attributes[:first_line]).to eq labware.name
      expect(attributes[:second_line]).to match(/, P/)
      expect(attributes[:third_line]).to eq labware.purpose.name
      expect(attributes[:fourth_line]).to eq Time.zone.today.strftime('%e-%^b-%Y')
      expect(attributes[:round_label_top_line]).to eq labware.barcode.prefix
      expect(attributes[:round_label_bottom_line]).to eq labware.barcode.human[2..]
      expect(attributes[:barcode]).to eq labware.barcode.human
    end
  end
end
