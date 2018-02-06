# frozen_string_literal: true

class Tubes::WorkCompletionsController < ApplicationController
  include WorkCompletionBehaviour

  before_action :check_for_current_user!

  def labware
    @labware ||= api.tube.find(params[:limber_tube_id])
  end
end
