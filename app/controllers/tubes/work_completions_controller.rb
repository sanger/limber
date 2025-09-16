# frozen_string_literal: true

# Handles the clicking of the 'Charge and Pass Libraries' button for tubes
# @see WorkCompletionBehaviour::create
class Tubes::WorkCompletionsController < ApplicationController
  include WorkCompletionBehaviour

  before_action :check_for_current_user!

  def labware
    @labware ||= Sequencescape::Api::V2.tube_for_completion(params[:tube_id])
  end
end
