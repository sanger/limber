# frozen_string_literal: true

module Presenters
  #
  # This version of the Presenter is for Bioscan, to only show the PCR 1 plate creation button
  # if there are valid lirbary prep requests.
  class BioscanSubmissionWhenPassedPlatePresenter < SubmissionWhenPassedPlatePresenter
    # Checks for in progress requests before allowing the child creation button to show
    def active_pipelines
      Settings.pipelines.active_pipelines_for_in_progress_requests(labware)
    end
  end
end
