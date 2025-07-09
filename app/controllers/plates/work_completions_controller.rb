# frozen_string_literal: true

# Handles the clicking of the 'Charge and Pass Libraries' button for plates
# @see WorkCompletionBehaviour::create
class Plates::WorkCompletionsController < ApplicationController
  include WorkCompletionBehaviour

  before_action :check_for_current_user!

  def labware
    @labware ||= Sequencescape::Api::V2.plate_for_completion(params[:plate_id])
  end
end
