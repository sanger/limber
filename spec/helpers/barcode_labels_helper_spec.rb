# frozen_string_literal: true

# require 'rails_helper'

RSpec.describe BarcodeLabelsHelper do
  include described_class

  describe '#barcode_printing_form' do
    let(:plate) { create(:plate) }
    let!(:purpose_config) { create(:stock_plate_with_info_config, uuid: 'stock-plate-purpose-uuid') }
    let(:labels) { [Labels::PlateLabel.new(plate, {})] }
    let(:redirection_url) { 'example_plate_url' }
    let(:default_printer_name) { 'example_printer_name' }
    let(:barcode_printers_request) { stub_barcode_printers(create_list(:plate_barcode_printer, 3)) }
    let(:presenter) { Presenters::StockPlatePresenter.new(labware: plate) }

    before do
      barcode_printers_request
      @printers = Sequencescape::Api::V2::BarcodePrinter.all
      @presenter = presenter
    end

    it 'renders a partial' do
      barcode_printing_form(labels:, redirection_url:, default_printer_name:)
      expect(rendered).to be_truthy
    end

    it 'has the right locals set' do
      barcode_printing_form(labels:, redirection_url:, default_printer_name:)

      printer_types = labels.map(&:printer_type)
      printers = @printers.select { |printer| printer_types.include?(printer.barcode_type) }

      expect(rendered).to include(printers[0].name)
      expect(rendered).to include(printers[1].name)
      expect(rendered).to include(labels[0].labware.labware_barcode.human)
    end
  end
end
