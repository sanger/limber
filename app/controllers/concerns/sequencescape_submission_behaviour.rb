# frozen_string_literal: true

# Module SequencescapeSubmissionBehaviour provides the ability to
# generate submissions to controllers
#
# @author Genome Research Ltd.
#
module SequencescapeSubmissionBehaviour
  # Builds a submission using the supplied params[:sequencescape_submission]
  def create_submission
    ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
    if ss.save
      flash[:notice] ||= []
      flash[:notice] << 'Your submissions have been made and should be built shortly.'
    else
      flash[:alert] = truncate_flash(ss.errors.full_messages)
    end
  end

  def sequencescape_submission_parameters
    params
      .require(:sequencescape_submission)
      .permit(:template_uuid, :labware_barcode, request_options: {}, assets: [], asset_groups: {}, extra_barcodes: [])
      .merge(user: current_user_uuid)
  end
end
