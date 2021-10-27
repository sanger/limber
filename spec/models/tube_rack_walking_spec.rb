# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TubeRackWalking::Walker do
  subject { TubeRackWalking::Walker.new(rack) }

  context 'A v2 rack' do
    let(:rack) { build :tube_rack, tubes: tubes }

    let(:tubes) do
      {
        'A1' => create(:v2_tube),
        'B1' => create(:v2_tube),
        'H10' => create(:v2_tube)
      }
    end

    it 'yields for each row' do
      expect { |b| subject.each(&b) }.to yield_control.exactly(8).times
    end

    it 'yields the row name as a argument' do
      expect(subject.each.map { |desc, _array| desc }).to eq(%w[A B C D E F G H])
    end

    it 'yields the expected tubes for each location' do
      subject.each do |desc, array|
        array.each_with_index do |tube, i|
          expect(tube).to eq(tubes["#{desc}#{i + 1}"])
        end
      end
    end
  end
end
