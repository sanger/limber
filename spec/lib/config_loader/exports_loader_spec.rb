# frozen_string_literal: true

require 'rails_helper'
require 'config_loader/exports_loader'

RSpec.describe ConfigLoader::ExportsLoader, :loader, type: :model do
  subject(:loader) { described_class.new(directory: test_directory, files: selected_files) }

  let(:test_directory) { Rails.root.join('spec/fixtures/config/exports') }
  let(:expected_count) do
    # Compute the expected number of exports.
    files_to_load =
      if selected_files
        [File.join(test_directory, "#{selected_files}.yml")] # specific files
      else
        Dir.glob("#{test_directory}/*.yml") # all files
      end

    # The total number of exports for selected_files.
    files_to_load.sum do |file|
      YAML.load_file(file).keys.count
    rescue StandardError
      0
    end
  end

  context 'with no files specified' do
    let(:selected_files) { nil }

    it 'loads exports from all files' do
      expect(loader.config.length).to eq expected_count
      expect(loader.config).to be_a(Hash)
    end
  end

  context 'with a specific file specified' do
    let(:selected_files) { 'exports' }

    it 'loads exports from specified files' do
      expect(loader.config.length).to eq expected_count
      expect(loader.config).to be_a(Hash)
    end
  end
end
