class PrintJobsController < ApplicationController

  def create
    @print_job = PrintJob.new(printer_name: print_job_params[:printer_name], printer_type: print_job_params[:printer_type], labels: print_job_params[:labels], number_of_copies: print_job_params[:number_of_copies].to_i)
    if @print_job.execute
      flash.notice = "Your label(s) have been sent to #{print_job_params[:printer_name]}"
    else
      flash.alert = @print_job.errors.full_messages
    end
    redirect_to :back
  end

  def print_job_params
    params.require(:print_job).permit!.to_h
  end

end