# frozen_string_literal: true

# Receives AJAX requests when creating tag plates, returns the
# plate information eg. lot number, template
# The front end makes a decision regarding suitability
class TagPlatesController < ApplicationController
  INCLUDES = [:labware, { lot: [{ lot_type: :target_purpose }, :template] }].freeze

  def show
    qcable_resource = Sequencescape::Api::V2::Qcable.includes(*INCLUDES).find(uuid: params[:id]).first
    qcable_presenter = Presenters::QcablePresenter.new(qcable_resource)
    respond_to { |format| format.json { render json: { 'qcable' => qcable_presenter } } }
  end
end
