# frozen_string_literal: true

require 'rails_helper'
require 'config_loader/pipelines_loader'

RSpec.describe ConfigLoader::PipelinesLoader, :loader, type: :model do
  subject(:loader) { described_class.new(directory: test_directory, files: selected_files) }

  let(:test_directory) { Rails.root.join('spec/fixtures/config/pipelines') }

  context 'with no files specified' do
    let(:selected_files) { nil }

    it 'loads purposes from all files' do
      expect(loader.config.length).to eq 4
      expect(loader.config).to be_a(Hash)
    end
  end

  context 'with a specific file specified' do
    let(:selected_files) { 'test_set_a' }

    it 'loads purposes from specified files' do
      expect(loader.config.length).to eq 2
      expect(loader.config).to be_a(Hash)
    end

    it 'loads purposes from specified files' do
      expect(loader.pipelines).to be_a(PipelineList)
    end
  end
end
