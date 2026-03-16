# frozen_string_literal: true

# Include in a presenter to add support for creating a submission
module Presenters::SubmissionBehaviour
  def each_submission_option
    purpose_config.submission_options.each do |button_text, options|
      submission_options = options.to_hash
      submission_options[:asset_groups] = asset_groups
      submission_options[:labware_barcode] = labware.labware_barcode.human
      yield button_text, SequencescapeSubmission.new(submission_options)
    end
  end

  def submissions
    labware.direct_submissions
  end

  def pending_submissions?
    submissions.any? { |submission| submission.building_in_progress?(ready_buffer: 20.seconds) }
  end

  # Determine whether the Choose Workflow buttons should be displayed
  def allow_new_submission?
    !(pending_submissions? || active_submissions?)
  end

  private

  def asset_groups
    @asset_groups ||=
      if labware.type == 'tubes'
        [{ assets: [labware.uuid], autodetect_studies: true, autodetect_projects: true }]
      else
        labware
          .wells
          .reject { |well| exclude_well?(well) }
          .group_by(&:order_group)
          .map { |_, wells| format_asset_group(wells) }
      end
  end

  def exclude_well?(well)
    empty_well?(well) || all_aliquot_requests_failed?(well)
  end

  def empty_well?(well)
    well.aliquots.blank?
  end

  def all_aliquot_requests_failed?(well)
    well.aliquots.present? && well.aliquots.all? { |aliquot| aliquot_request_failed?(aliquot) }
  end

  def aliquot_request_failed?(aliquot)
    aliquot.request&.state == 'failed'
  end

  def format_asset_group(wells)
    { assets: wells.map(&:uuid), autodetect_studies: true, autodetect_projects: true }
  end

  def active_submissions?
    # Guard for zero submissions, ok to make a new one
    return false if submissions.blank?

    # NB. submission state just tells you the state of the asynchronous sequencescape submission creation
    # job, not the state of the submission requests. State 'ready' means job completed successfully.
    # If any submission is not yet ready, it is still being built and we should not make more submissions
    return false unless submissions.all?(&:ready?)

    # Check if any submission requests are incomplete (not passed, failed, cancelled)
    # Returns true if all requests are completed, false otherwise (indicating a submission is still active).
    submissions.any? { |submission| submission_ready_with_incomplete_requests?(submission) }
  end

  def submission_ready_with_incomplete_requests?(submission)
    return false unless submission.ready?

    labware.wells.any? { |well| well_has_incomplete_requests?(well) }
  end

  def well_has_incomplete_requests?(well)
    well.requests_as_source.any? { |request| incomplete_request_state?(request.state) }
  end

  def incomplete_request_state?(state)
    %w[passed failed cancelled].exclude?(state)
  end
end
