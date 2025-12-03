# frozen_string_literal: true

# Print new barcode labels
# Pretty simple wrapper for print job, and incredibly un-opinionated, simply passes
# the parameters straight through to the print job.
class PrintJobsController < ApplicationController
  def create
    @print_job = PrintJob.new(print_job_params)
    @print_job.printer = find_printer_from_name

    if @print_job.execute
      flash.notice = "Your label(s) have been sent to #{print_job_params[:printer_name]}"
    else
      flash.alert = truncate_flash(@print_job.errors.full_messages.uniq)
    end
    redirect_back_or_to(:root)
  end

  private

  def print_job_params
    params
      .require(:print_job)
      .permit(:printer_name, :label_templates_by_service, :number_of_copies)
      .tap do |permitted|
        # We want to permit ALL labels content, as it is an array of unstructured hashes.
        # While you can #permit arrays of 'scalars' you can't permit arrays of hashes.
        # While we COULD carefully define the current label structure, we gain nothing by doing so and make
        # future changes more painful.
        permitted[:labels] = params.require(:print_job)[:labels].map(&:permit!)
        permitted[:labels_sprint] = params.require(:print_job)[:labels_sprint].permit!
      end
  end

  def find_printer_from_name
    # there's bound to be a better way of doing this, so we don't have to
    # requery all the printers here to find the right one
    printers = Sequencescape::Api::V2::BarcodePrinter.all
    printers.find { |p| p.name == print_job_params[:printer_name] }
  end
end
