# frozen_string_literal: true

require 'rails_helper'
require 'config_loader/pipelines_loader'

RSpec.describe ConfigLoader::PipelinesLoader, type: :model, loader: true do
  subject(:loader) { described_class.new(directory: test_directory, files: selected_files) }

  let(:test_directory) { Rails.root.join('spec/fixtures/config/pipelines') }
  let(:created_purposes) { ['Basic Plate', 'Other Plate', 'Type with creator'] }

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
