class BarcodeLabelsController < ApplicationController
  before_filter :initialize_printer_and_barcode_service
  def initialize_printer_and_barcode_service
    raise StandardError, "No printer specified!" if params[:printer].blank?

    @printer = api.barcode_printer.find(params[:printer])
    @service = Sanger::Barcode::Printing::Service.new(@printer.service.url)
  end
  private :initialize_printer_and_barcode_service

  # Creates a label
  def create_label(details)
    Sanger::Barcode::Printing::Label.new(details)
  end
  private :create_label

  # Does the actual printing of the labels passed
  def print(labels)
    @service.print_labels(Array(labels), @printer.name, @printer.type.layout)
  end
  private :print

  # Handles printing a single label
  def individual
    print(create_label(params[:label]))
    redirect_to(params[:redirect_to], :notice => "Barcode printed to #{@printer.name}")
  end

  before_filter :convert_labels_to_array, :only => :multiple
  def convert_labels_to_array
    params[:labels] = params.fetch(:labels, []).map { |_, v| v }
  end
  private :convert_labels_to_array

  # Handles printing multiple labels
  def multiple
    print(params[:labels].map(&method(:create_label)))
    redirect_to(params[:redirect_to], :notice => "#{params[:labels].size} barcodes printed to #{@printer.try(:name)}")
  end
end
