# frozen_string_literal: true

# Module WorkCompletionBehaviour provides work completion
# endpoints for controllers
#
# @author Genome Research Ltd.
#
module WorkCompletionBehaviour
  # Create a work completion for the given limber_plate_id
  # and redirect to the plate page.
  # Work completions mark library creation requests as completed
  # and hook them up to the correct wells.
  # rubocop:todo Metrics/MethodLength
  def create # rubocop:todo Metrics/AbcSize
    messages = Hash.new { |message_store, category| message_store[category] = [] }
    api.work_completion.create!(
      # Our pools keys are our submission uuids.
      submissions: labware.in_progress_submission_uuids,
      target: labware.uuid,
      user: current_user_uuid
    )
    messages[:notice] << 'Requests have been passed'

    if params[:sequencescape_submission]
      ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
      if ss.save
        messages[:notice] << 'Your submissions have been made and should be built shortly.'
      else
        messages[:alert] = truncate_flash(ss.errors.full_messages)
      end
    end
    redirect_to labware, messages
  end
  # rubocop:enable Metrics/MethodLength

  def sequencescape_submission_parameters
    params
      .require(:sequencescape_submission).permit(:template_uuid, request_options: {}, assets: [])
      .merge(api: api, user: current_user_uuid)
  end
end
