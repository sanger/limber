class BarcodeLabelsController < ApplicationController
  before_filter :initialize_printer_and_barcode_service
  def initialize_printer_and_barcode_service
    raise StandardError, "No printer specified!" if params[:printer].blank?
    raise StandardError, "No copies specified!" if params[:number].blank? || params[:number].to_i <= 0
    raise StandardError, "Can only request up to #{Settings.printers.limit} copies!" if params[:number].to_i > Settings.printers.limit

    @printer = api.barcode_printer.find(params[:printer])
    @service = Sanger::Barcode::Printing::Service.new(@printer.service.url)
    @copies = params[:number].to_i
  end
  private :initialize_printer_and_barcode_service

  # Creates a label
  def create_label(details)
    details[:type] = "custom-labels"
    Sanger::Barcode::Printing::Label.new(details)
  end
  private :create_label

  # Does the actual printing of the labels passed
  def print(labels)
    @service.print_labels(Array(labels)*@copies, @printer.name, @printer.type.layout)
  end
  private :print

  # Handles printing a single label
  def individual
    begin
      print(create_label(params[:label]))
      redirect_to(params[:redirect_to], :notice => "Barcode printed to #{@printer.name}")
    rescue BarcodeException
      redirect_to(params[:redirect_to], :alert => "There was a problem with the printer. Select another and try again.")
    end
  end

  before_filter :convert_labels_to_array, :only => :multiple
  def convert_labels_to_array
    params[:labels] = params.fetch(:labels, []).map { |_, v| v }
  end
  private :convert_labels_to_array

  # Handles printing multiple labels
  def multiple
    begin
      print(params[:labels].map(&method(:create_label)))
      redirect_to(params[:redirect_to], :notice => "#{params[:labels].size} barcodes printed to #{@printer.try(:name)}")
    rescue BarcodeException
      redirect_to(params[:redirect_to], :alert => "There was a problem with the printer. Select another and try again.")
    end
  end
end
