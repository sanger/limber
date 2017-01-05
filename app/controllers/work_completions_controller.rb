# frozen_string_literal: true

class WorkCompletionsController < ApplicationController
  before_action :check_for_current_user!
  # Create a work completion for the given limber_plate_id
  # and redirect to the plate page.
  # Work completions mark library creation requests as completed
  # and hook them up to the correct wells.
  def create
    plate = api.plate.find(params[:limber_plate_id])

    api.work_completion.create!(
      # Our pools keys are our submission uuids.
      submissions: plate.pools.keys,
      target: params[:limber_plate_id],
      user: current_user_uuid
    )
    redirect_to limber_plate_path(params[:limber_plate_id]), notice: 'Requests have been passed'
  end
end
