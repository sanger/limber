# frozen_string_literal: true

require 'rails_helper'
require 'config_loader/exports_loader'

RSpec.describe ConfigLoader::ExportsLoader, type: :model, loader: true do
  subject(:loader) do
    described_class.new(directory: test_directory, files: selected_files)
  end

  let(:test_directory) { Rails.root.join('spec/fixtures/config/exports') }

  context 'with no files specified' do
    let(:selected_files) { nil }

    it 'loads purposes from all files' do
      expect(loader.config.length).to eq 25
      expect(loader.config).to be_a(Hash)
    end
  end

  context 'with a specific file specified' do
    let(:selected_files) { 'exports' }

    it 'loads purposes from specified files' do
      expect(loader.config.length).to eq 25
      expect(loader.config).to be_a(Hash)
    end
  end
end
