# frozen_string_literal: true

# Handles upload, listing and download of qc files.
# Finds source asset depending of the provided parameters
# index => Ajaxy rendering of the files attached to a plate/tube/tube_rack
# show => Retrieve a particular file
# create => Attach a new file to a plate/tube/tube_rack
class QcFilesController < ApplicationController
  attr_reader :asset, :asset_path

  before_action :find_assets, only: %i[create index]

  def index
    respond_to { |format| format.json { render json: { 'qc_files' => asset.qc_files.map { |q| qc_file_to_json(q) } } } }
  end

  def show
    qc_file = Sequencescape::Api::V2::QcFile.find(uuid: params[:id]).first
    send_data(qc_file.contents, filename: qc_file.filename, type: 'sequencescape/qc_file')
  end

  def create
    Sequencescape::Api::V2::QcFile.create_for_labware!(
      contents: params['qc_file'].read,
      filename: params['qc_file'].original_filename,
      labware: asset
    )
    redirect_to(
      asset_path,
      notice: 'Your file has been uploaded and is available from the file tab' # rubocop:todo Rails/I18nLocaleTexts
    )
  end

  private

  def qc_file_to_json(qc_file)
    { filename: qc_file.filename, size: qc_file.size, uuid: qc_file.uuid, created: qc_file.created_at.to_fs(:long) }
  end

  def find_assets
    %w[plate tube tube_rack].each do |klass|
      next if params["#{klass}_id"].nil?

      @asset_path = send(:"#{klass}_path", params["#{klass}_id"])
      @asset = Sequencescape::Api::V2::Labware.find(uuid: params["#{klass}_id"]).first
      return true
    end
    false
  end
end
