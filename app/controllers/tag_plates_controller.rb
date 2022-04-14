# frozen_string_literal: true

# Receives AJAX requests when creating tag plates, returns the
# plate information eg. lot number, template, status
# The front end makes a decision regarding suitability
class TagPlatesController < ApplicationController
  def show
    qcable = Presenters::QcablePresenter.new(api.qcable.find(params[:id]))
    respond_to { |format| format.json { render json: { 'qcable' => qcable } } }
  end
end
