# frozen_string_literal: true

# Module WorkCompletionBehaviour provides work completion
# endpoints for controllers
#
# @author Genome Research Ltd.
#
module WorkCompletionBehaviour
  extend ActiveSupport::Concern

  included { include SequencescapeSubmissionBehaviour }

  # Create a work completion for the given limber_plate_id
  # and redirect to the plate page.
  # Work completions mark library creation requests as completed
  # and hook them up to the correct wells.
  def create
    api.work_completion.create!(
      # Our pools keys are our submission uuids.
      submissions: labware.in_progress_submission_uuids,
      target: labware.uuid,
      user: current_user_uuid
    )

    # We assign the message in an array as create_submission may wish to add
    # its own feedback.
    flash[:notice] = ['Requests have been passed']

    create_submission if params[:sequencescape_submission]

    redirect_to labware
  end

  def sequencescape_submission_parameters
    params
      .require(:sequencescape_submission)
      .permit(:template_uuid, request_options: {}, assets: [])
      .merge(api: api, user: current_user_uuid)
  end
end
