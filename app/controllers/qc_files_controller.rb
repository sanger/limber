# frozen_string_literal: true

class QcFilesController < ApplicationController
  def show
    response = api.qc_file.find(params[:id]).retrieve
    filename = /filename="([^"]*)"/.match(response['Content-Disposition'])[1] || 'unnamed_file'
    send_data(response.body, filename: filename, type: 'sequencescape/qc_file')
  end

  def create
    asset.qc_files.create_from_file!(params['qc_file'], params['qc_file'].original_filename)
    redirect_to(asset_path)
  end

  attr_reader :asset, :asset_path

  private

  before_action :find_assets

  def find_assets
    %w(limber pulldown).each do |app_name|
      %w(plate tube multiplexed_library_tube).each do |klass|
        next if params["#{app_name}_#{klass}_id"].nil?
        @asset_path = send(:"#{app_name}_#{klass}_path", params["#{app_name}_#{klass}_id"])
        @asset      = api.send(:"#{klass}").find(params["#{app_name}_#{klass}_id"])
        return true
      end
    end
    if params['limber_tube_id']
      @asset_path = limber_tube_path(params['limber_tube_id'])
      @asset      = api.tube.find(params['limber_tube_id'])
      return true
    end
    false
  end
end
