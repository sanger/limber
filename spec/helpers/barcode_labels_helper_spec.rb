# frozen_string_literal: true

# require 'rails_helper'

RSpec.describe BarcodeLabelsHelper do
  include BarcodeLabelsHelper

  describe '#barcode_printing_form' do
    has_a_working_api

    let(:plate) { create(:v2_plate) }
    let(:labels) { [Labels::PlateLabel.new(plate, {})] }
    let(:redirection_url) { 'example_plate_url' }
    let(:default_printer_name) { 'example_printer_name' }
    let(:barcode_printers_request) { stub_api_get('barcode_printers', body: json(:barcode_printer_collection)) }
    let(:presenter) { Presenters::StockPlatePresenter.new }

    before do
      barcode_printers_request
      @printers = api.barcode_printer.all
      @presenter = presenter
    end

    it 'renders a partial' do
      barcode_printing_form(labels: labels, redirection_url: redirection_url, default_printer_name: default_printer_name)
      expect(rendered).to be_truthy
    end

    it 'has the right locals set' do
      barcode_printing_form(labels: labels, redirection_url: redirection_url, default_printer_name: default_printer_name)

      printer_types = labels.map(&:printer_type)
      printers = @printers.select { |printer| printer_types.include?(printer.type.name) }

      expect(rendered).to include(printers[0].name)
      expect(rendered).to include(printers[1].name)
      expect(rendered).to include(labels[0].labware.labware_barcode.human)
    end
  end
end
