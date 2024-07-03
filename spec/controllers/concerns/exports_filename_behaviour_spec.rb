# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportsFilenameBehaviour do
  let(:dummy_class) { Struct.new(:export, :response) { include ExportsFilenameBehaviour } }

  describe '#set_filename' do
    let(:filename) { 'filename' }
    let(:labware) do
      double(
        'labware',
        barcode: double('barcode', human: '12345'),
        parents: [double('labware', barcode: double('barcode', human: '67890'))]
      )
    end
    let(:page) { 0 }
    let(:export) { Export.new(csv: filename) }
    let(:response) { double('response', headers: {}) }
    let(:dummy_instance) { dummy_class.new(export, response) }

    before { allow(dummy_instance).to receive(:response).and_return(response) }

    it 'sets the correct filename when no extra filename data is included' do
      allow(dummy_instance).to receive(:export).and_return(export)

      dummy_instance.set_filename(labware, page)

      expect(response.headers['Content-Disposition']).to eq 'attachment; filename="filename.csv"'
    end

    it 'sets the correct filename and file extension for the export' do
      export =
        Export.new(
          filename: {
            'name' => filename,
            'labware_barcode' => {
              'prepend' => true,
              'append' => true
            },
            'include_page' => true
          },
          csv: 'csv',
          file_extension: 'tsv'
        )
      allow(dummy_instance).to receive(:export).and_return(export)
      dummy_instance.set_filename(labware, page)

      expect(response.headers['Content-Disposition']).to eq 'attachment; filename="12345_filename_12345_1.tsv"'
    end

    it 'sets the correct filename when a parent barcode is given' do
      export =
        Export.new(
          csv: 'csv-filename',
          filename: {
            'name' => filename,
            'parent_labware_barcode' => {
              'prepend' => true,
              'append' => true
            },
            'include_page' => true
          }
        )
      allow(dummy_instance).to receive(:export).and_return(export)
      dummy_instance.set_filename(labware, page)

      expect(response.headers['Content-Disposition']).to eq 'attachment; filename="67890_filename_67890_1.csv"'
    end
  end
end
