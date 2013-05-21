class QcFilesController < ApplicationController

  def show
    response = api.qc_file.find(params[:id]).retrieve
    filename = /filename="([^"]*)"/.match(response['Content-Disposition'])[1]||"unnamed_file"
    send_data(response.body, :filename => filename, :type => 'sequencescape/qc_file')
  end

  def create
    plate.qc_files.create_from_file!(params['qc_file'], params['qc_file'].original_filename)
    redirect_to(illumina_b_plate_path(params['illumina_b_plate_id']))
  end

  def plate
    api.plate.find(params['illumina_b_plate_id'])
  end

end
