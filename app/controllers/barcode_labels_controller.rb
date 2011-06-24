class BarcodeLabelsController < ApplicationController
  def create
    printer = api.barcode_printer.find(params[:printer])

    service = Sanger::Barcode::Printing::Service.new(printer.service.url)
    label   = Sanger::Barcode::Printing::Label.new(params[:label])
    service.print_labels([label], printer.name, printer.type.layout)
    redirect_to(plate_path(params[:label][:plate_uuid]), :notice => "Barcode printed to #{printer.name}")
  end
end
