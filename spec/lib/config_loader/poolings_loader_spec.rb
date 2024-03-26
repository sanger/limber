# frozen_string_literal: true

require 'config_loader/poolings_loader'

RSpec.describe ConfigLoader::PoolingsLoader, type: :model, loader: true do
  subject(:loader) { described_class.new(directory: test_directory, files: selected_files) }

  let(:test_directory) { Rails.root.join('spec/fixtures/config/poolings') }

  context 'with no files specified' do
    let(:selected_files) { nil }

    it 'loads purposes from all files' do
      expect(loader.config.length).to eq 2
      expect(loader.config).to be_a(Hash)
      expect(loader.config.keys).to include('donor_pooling', 'second_pooling_config')
      expect(loader.config.dig('donor_pooling', 'number_of_pools')&.size).to eq(96)
      expect(loader.config.dig('second_pooling_config', 'number_of_pools')&.size).to eq(4)
    end
  end

  context 'with a specific file specified' do
    let(:selected_files) { 'donor_pooling' }

    it 'loads purposes from specified files' do
      expect(loader.config.length).to eq 1
      expect(loader.config).to be_a(Hash)
      expect(loader.config.dig('donor_pooling', 'number_of_pools')&.size).to eq(96)
      expect(loader.config['donor_pooling']['number_of_pools'][1]).to eq(1)
      expect(loader.config['donor_pooling']['number_of_pools'][96]).to eq(8)
    end
  end
end
