# frozen_string_literal: true
class PrintJobsController < ApplicationController
  def create
    @print_job = PrintJob.new(print_job_params)
    if @print_job.execute
      flash.notice = "Your label(s) have been sent to #{print_job_params[:printer_name]}"
    else
      flash.alert = @print_job.errors.full_messages.uniq
    end
    redirect_back(fallback_location: :root)
  end

  private

  def print_job_params
    params.require(:print_job).permit(:printer_name, :printer_type, :number_of_copies).tap do |permitted|
      # We want to permit ALL labels content, as it is an array of unstructured hashes.
      # While you can #permit arrays of 'scalars' you can't permit arrays of hashes.
      # While we COULD carefully define the current label structure, we gain nothing by doing so and make
      # future changes more painful.
      permitted[:labels] = params.require(:print_job)[:labels].map(&:permit!)
    end
  end
end
