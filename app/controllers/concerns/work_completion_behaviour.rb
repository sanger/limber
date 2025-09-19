# frozen_string_literal: true

# Module WorkCompletionBehaviour provides work completion
# endpoints for controllers
#
# @author Genome Research Ltd.
#
module WorkCompletionBehaviour
  extend ActiveSupport::Concern

  included { include SequencescapeSubmissionBehaviour }

  # Create a work completion for the given labware ID and redirect to the labware's page.
  # Work completions mark library creation requests as completed and hook them up to the correct wells.
  def create
    Sequencescape::Api::V2::WorkCompletion.create!(
      # Our pools keys are our submission uuids.
      submission_uuids: labware.in_progress_submission_uuids.compact,
      target_uuid: labware.uuid,
      user_uuid: current_user_uuid
    )

    # We assign the message in an array as create_submission may wish to add its own feedback.
    flash[:notice] = ['Requests have been passed']

    create_submission if params[:sequencescape_submission]

    redirect_to labware
  end

  def sequencescape_submission_parameters
    params
      .require(:sequencescape_submission)
      .permit(:template_uuid, request_options: {}, assets: [])
      .merge(user: current_user_uuid)
  end
end
