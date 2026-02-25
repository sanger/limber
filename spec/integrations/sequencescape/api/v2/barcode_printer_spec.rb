# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_examples'

RSpec.describe Sequencescape::Api::V2::BarcodePrinter do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  # Implement caching for test
  before(:each, :cache) do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe '.all', :cache do
    let(:api_base_class) { Sequencescape::Api::V2::Base }
    let(:printers) { %w[printer1 printer2 printer3] }

    before do
      allow(api_base_class).to receive(:all).and_return(printers)

      described_class.all
    end

    it 'calls the API to fetch all printers' do
      expect(api_base_class).to have_received(:all).once
    end

    it 'returns the list of printers' do
      expect(described_class.all).to eq(printers)
    end

    context 'when called multiple times within the cache expiry period' do
      before do
        2.times { described_class.all }
      end

      it 'calls the API only once' do
        expect(api_base_class).to have_received(:all).once
      end

      it 'returns the cached printers on subsequent calls' do
        expect(described_class.all).to eq(printers)
      end
    end

    context 'when cache is present but expired' do
      before do
        # Simulate cache expiry by advancing time beyond the cache expiry period
        travel 4.minutes
        described_class.all
      end

      it 'calls the API again to fetch printers' do
        expect(api_base_class).to have_received(:all).twice
      end

      it 'returns the new list of printers after cache expiry' do
        expect(described_class.all).to eq(printers)
      end
    end
  end
end
