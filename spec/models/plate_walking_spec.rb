# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlateWalking::Walker do
  subject { PlateWalking::Walker.new(plate, plate.wells) }

  context 'A v1 plate' do
    has_a_working_api
    let(:plate) { build :plate }
    before { stub_api_get(plate.uuid, 'wells', body: json(:well_collection)) }
    it 'yields wells in rows' do
      expect { |b| subject.each(&b) }.to yield_control.exactly(8).times
      expect(subject.each.map { |desc, _array| desc }).to eq(%w[A B C D E F G H])
      subject.each do |desc, array|
        array.each_with_index do |well, i|
          expect(well).to be_a Limber::Well
          expect(well.location).to eq("#{desc}#{i + 1}")
        end
      end
    end
  end

  context 'A v2 plate' do
    let(:plate) { build :v2_plate, well_count: 96 }

    it 'yields wells in rows' do
      expect { |b| subject.each(&b) }.to yield_control.exactly(8).times
      expect(subject.each.map { |desc, _array| desc }).to eq(%w[A B C D E F G H])
      subject.each do |desc, array|
        array.each_with_index do |well, i|
          expect(well).to be_a Sequencescape::Api::V2::Well
          expect(well.location).to eq("#{desc}#{i + 1}")
        end
      end
    end
  end
end
