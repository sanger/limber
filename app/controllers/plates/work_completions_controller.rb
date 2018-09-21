# frozen_string_literal: true

class Plates::WorkCompletionsController < ApplicationController
  include WorkCompletionBehaviour

  before_action :check_for_current_user!

  def labware
    @labware ||= Sequencescape::Api::V2::Plate.find_by(
      { uuid: params[:limber_plate_id] },
      includes: 'wells.aliquots.request.submission'
    )
  end
end
