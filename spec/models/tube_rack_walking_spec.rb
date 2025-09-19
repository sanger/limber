# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TubeRackWalking::Walker do
  subject { described_class.new(rack) }

  context 'A v2 rack' do
    let(:rack) { build :tube_rack, tubes: }

    let(:tubes) { { 'A1' => create(:tube), 'B1' => create(:tube), 'H10' => create(:tube) } }

    it 'yields for each row' do
      expect { |b| subject.each(&b) }.to yield_control.exactly(8).times
    end

    it 'yields the row name as a argument' do
      expect(subject.each.map { |desc, _array| desc }).to eq(%w[A B C D E F G H])
    end

    it 'yields the expected tubes for each location' do
      subject.each { |desc, array| array.each_with_index { |tube, i| expect(tube).to eq(tubes["#{desc}#{i + 1}"]) } }
    end
  end
end
