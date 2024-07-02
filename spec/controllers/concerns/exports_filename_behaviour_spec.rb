# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportsFilenameBehaviour do
    let(:dummy_class) { Struct.new(:export, :response) { include ExportsFilenameBehaviour } }

    describe '#set_filename' do
        let(:filename) { 'filename' }
        let(:file_extension) { 'csv' }
        let(:labware) do
            double('labware', barcode: double('barcode', human: '12345'), 
                    parents: [double('labware', barcode: double('barcode', human: '67890'))]) 
        end
        let(:page) { 0 }
        let(:export) do
            double('export', 
                filename: { 
                    'name' => filename,
                    'labware_barcode' => { 
                        'prepend' => true,
                        'append' => true
                    },
                    'include_page' => true
                }, 
                csv: 'csv', 
                file_extension: file_extension
            )
        end
        let(:response) { double('response', headers: { }) }
        let(:dummy_instance) { dummy_class.new(export, response)}

        before do
            allow(dummy_instance).to receive(:export).and_return(export)
            allow(dummy_instance).to receive(:response).and_return(response)
        end

        it 'sets the correct filename and file extension for the export' do
            dummy_instance.set_filename(labware, page)

            expect(response.headers['Content-Disposition']).to eq 'attachment; filename="12345_filename_12345_1.csv"'
        end

        it 'sets the correct filename when a parent barcode is given' do
            export = double('export', filename: { 
                'name' => filename, 
                'parent_labware_barcode' => { 'prepend' => true, 'append' => true },
                'include_page' => true,
                'file_extenion' => 'csv'
            }, file_extension:  file_extension)
            allow(dummy_instance).to receive(:export).and_return(export)
            dummy_instance.set_filename(labware, page)

            expect(response.headers['Content-Disposition']).to eq 'attachment; filename="67890_filename_67890_1.csv"'
        end

        it 'sets the correct filename when no extra filename data is included' do
            export = Export.new(csv: filename)
            allow(dummy_instance).to receive(:export).and_return(export)

            dummy_instance.set_filename(labware, page)

            expect(response.headers['Content-Disposition']).to eq 'attachment; filename="filename.csv"'
        end
    end
end
