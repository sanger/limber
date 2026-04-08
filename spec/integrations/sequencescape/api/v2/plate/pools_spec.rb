# frozen_string_literal: true

require 'rails_helper'

# Includes nested tests for Pool/Subpool

RSpec.describe Sequencescape::Api::V2::Plate::Pools do
  # Replacing the explicit class with described_class causes the tests to fail ¯\_(ツ)_/¯
  subject(:pools) { Sequencescape::Api::V2::Plate::Pools.new(plate.wells) } # rubocop:disable RSpec/DescribedClass

  let(:plate) { create :plate, pool_sizes: [2, 2], pool_pcr_cycles: [10, 6] }
  let(:number_of_pools) { 2 }

  describe '#number_of_pools' do
    it 'returns the number of pools' do
      expect(pools.number_of_pools).to eq number_of_pools
    end
  end

  describe '#each' do
    it 'yields once per pool' do
      expect { |b| pools.each(&b) }.to yield_successive_args(
        Sequencescape::Api::V2::Plate::Pool,
        Sequencescape::Api::V2::Plate::Pool
      )
    end
  end

  # Given pools acts a bit like a pool factory, we'll roll the tests in here.
  describe Sequencescape::Api::V2::Plate::Pool do
    let(:pool) { pools.first }

    describe '#well_count' do
      it 'returns the pool size' do
        expect(pool.well_count).to eq(2)
      end
    end

    describe '#subpools' do
      it 'returns an array of subpools' do
        expect(pool.subpools).to be_an Array
      end

      it 'confirms the size of the subpools' do
        expect(pool.subpools.length).to eq 1
      end
    end
  end

  describe Sequencescape::Api::V2::Plate::Subpool do
    let(:subpool) { pools.first.subpools.first }

    describe '#well_locations' do
      it 'returns an array well loactions' do
        expect(subpool.well_locations).to eq(%w[A1 B1])
      end
    end

    describe '#fragment_size' do
      it 'returns an fragment size' do
        expect(subpool.fragment_size).to eq Sequencescape::Api::V2::Request::FragmentSize.new(100, 200)
      end
    end

    describe '#library_type' do
      it 'returns the library type' do
        expect(subpool.library_type).to eq 'Standard'
      end
    end
  end
end
