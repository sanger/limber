# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlateWalking::Walker do
  subject { described_class.new(plate, plate.wells) }

  let(:plate) { build :plate }

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
