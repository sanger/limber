# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::FilenameHandler::Standard do
  let(:filename) { 'export_file' }
  let(:parent_labware) { build(:plate) }
  let(:labware) { build(:plate, parents: [parent_labware]) }
  let(:page) { 0 }
  let(:export) do
    instance_double(Export,
                    filename: export_filename_config)
  end

  context 'when no barcode options are specified' do
    let(:export_filename_config) { {} }

    it 'returns the original filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq(filename)
    end
  end

  context 'when labware barcode is to be prepended' do
    let(:export_filename_config) { { 'labware_barcode' => { 'prepend' => true } } }

    it 'prepends the labware barcode to the filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq("#{labware.human_barcode}_export_file")
    end
  end

  context 'when labware is a tube and barcode is to be prepended' do
    let(:labware) { build(:tube) }
    let(:export_filename_config) { { 'labware_barcode' => { 'prepend' => true } } }

    it 'prepends the labware barcode to the filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq("#{labware.human_barcode}_export_file")
    end
  end

  context 'when labware barcode is to be appended' do
    let(:export_filename_config) { { 'labware_barcode' => { 'append' => true } } }

    it 'appends the labware barcode to the filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq("export_file_#{labware.human_barcode}")
    end
  end

  context 'when parent labware barcode is to be prepended' do
    let(:export_filename_config) { { 'parent_labware_barcode' => { 'prepend' => true } } }

    it 'prepends the parent labware barcode to the filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq("#{parent_labware.human_barcode}_export_file")
    end
  end

  context 'when parent labware barcode is to be appended' do
    let(:export_filename_config) { { 'parent_labware_barcode' => { 'append' => true } } }

    it 'appends the parent labware barcode to the filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq("export_file_#{parent_labware.human_barcode}")
    end
  end

  context 'when both labware and parent barcodes are appended' do
    let(:export_filename_config) do
      {
        'labware_barcode' => { 'append' => true },
        'parent_labware_barcode' => { 'append' => true }
      }
    end

    it 'appends both barcodes in order' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq("export_file_#{labware.human_barcode}_#{parent_labware.human_barcode}")
    end
  end

  context 'when include_page is true' do
    let(:export_filename_config) { { 'include_page' => true } }

    it 'appends the page number to the filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq('export_file_1')
    end
  end

  context 'when all options are used' do
    let(:export_filename_config) do
      {
        'labware_barcode' => { 'prepend' => true },
        'parent_labware_barcode' => { 'append' => true },
        'include_page' => true
      }
    end

    it 'applies all options in correct order' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq("#{labware.human_barcode}_export_file_#{parent_labware.human_barcode}_1")
    end
  end

  context 'when parent labware is blank' do
    let(:export_filename_config) { { 'parent_labware_barcode' => { 'append' => true } } }

    before { allow(labware).to receive(:parents).and_return(nil) }

    it 'returns the original filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq(filename)
    end
  end
end
