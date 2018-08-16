# frozen_string_literal: true

require 'spec_helper'

# CreationForm is the base class for our forms
RSpec.describe Limber::Plate do
  has_a_working_api

  subject(:plate) { build :plate, transfer_request_collections_count: 2 }
  let(:transfer_request_collections_json) do
    json :transfer_request_collection_collection
  end

  before do
    stub_api_get(plate.uuid, 'wells', body: json(:well_collection))
    stub_api_get(plate.uuid, 'transfer_request_collections', body: transfer_request_collections_json)
  end

  describe '#tubes_and_sources' do
    subject { plate.tubes_and_sources }
    it { is_expected.to be_a Array }

    it 'is a hash of tubes' do
      expect(subject.map(&:first).length).to eq 2
      subject.map(&:first).each_with_index do |tube, index|
        expect(tube.uuid).to eq("target-#{index}-uuid")
      end
    end

    it 'has an array of source wells' do
      expect(subject.map(&:last)).to be_a Array
    end

    it 'finds the correct source wells' do
      expect(subject.map(&:last).first).to eq(%w[A1 B1])
      expect(subject.map(&:last).last).to eq(%w[C1 D1])
    end
  end
end
