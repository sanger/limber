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

  def pending_submissions?
    submissions.any? { |submission| submission.building_in_progress?(ready_buffer: 20.seconds) }
  end

  def submissions
    labware.direct_submissions
  end

  private

  def asset_groups
    @asset_groups ||=
      labware
        .wells
        .compact_blank
        .group_by(&:order_group)
        .map { |_, wells| { assets: wells.map(&:uuid), autodetect_studies: true, autodetect_projects: true } }
  end
end
