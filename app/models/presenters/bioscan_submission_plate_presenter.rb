# frozen_string_literal: true

module Presenters
  #
  # This version of the SubmissionPlatePresenter only displays the child creation button
  # if it has active requests which match the pipeline filters.
  # Used specifically for Bioscan PCR 1 plate creation.
  #
  class BioscanSubmissionPlatePresenter < SubmissionPlatePresenter
    def active_pipelines
      Settings.pipelines.active_pipelines_for_in_progress_requests(labware)
    end
  end
end
