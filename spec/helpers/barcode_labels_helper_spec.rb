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

    # let(:printers) { build(:barcode_printer_collection) }
    let(:printers) { [ build(:plate_barcode_printer), build(:tube_barcode_printer) ] }

    # let(:printer) { build(:plate_barcode_printer) }

    before do
      @printers = printers
      # puts "@printers: #{@printers}"
      # puts "@printers.class: #{@printers.class}"
      # puts "printer.type: #{printer.type}"
      # binding.pry
    end

    it 'renders a partial' do
      puts "Start of test"
      # Currently failing due to @printers variable not having correct structure
      # Been struggling with the barcode printer factories
      barcode_printing_form(labels: labels, redirection_url: redirection_url, default_printer_name: default_printer_name)
    end

    it 'has the right locals set' do
      # TODO
    end
  end
end
