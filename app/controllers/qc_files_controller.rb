# frozen_string_literal: true

class QcFilesController < ApplicationController
  attr_reader :asset, :asset_path

  before_action :find_assets, only: %i[create index]

  def index
    respond_to do |format|
      format.json { render json: { 'qc_files' => asset.qc_files } }
    end
  end

  def show
    response = api.qc_file.find(params[:id]).retrieve
    filename = /filename="([^"]*)"/.match(response['Content-Disposition'])[1] || 'unnamed_file'
    send_data(response.body, filename: filename, type: 'sequencescape/qc_file')
  end

  def create
    asset.qc_files.create_from_file!(params['qc_file'], params['qc_file'].original_filename)
    redirect_to(asset_path, notice: 'Your file has been uploaded and is available from the file tab')
  end

  private

  def find_assets
    %w[plate tube multiplexed_library_tube].each do |klass|
      next if params["limber_#{klass}_id"].nil?

      @asset_path = send(:"limber_#{klass}_path", params["limber_#{klass}_id"])
      @asset      = api.send(:"#{klass}").find(params["limber_#{klass}_id"])
      return true
    end
    false
  end
end
