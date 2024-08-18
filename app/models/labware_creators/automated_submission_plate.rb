# frozen_string_literal: true

module LabwareCreators
  # Experimental labware creator to do automated submission before creation.
  class AutomatedSubmissionPlate < StampedPlate
    def create_labware!
      create_and_build_submission
      super
    end

    def create_and_build_submission
      submission_options_from_config = purpose_config.submission_options
      autodetect_studies = autodetect_projects = true
      sequencescape_submission_parameters =
        {
          api: api,
          user: user_uuid,
          asset_groups: [
            { assets: asset_uuids, autodetect_studies: autodetect_studies, autodetect_projects: autodetect_projects }
          ]
        }.merge(submission_options_from_config.values.first)
      create_submission(sequencescape_submission_parameters)
    end

    def asset_uuids
      parent.wells.map(&:uuid)
    end

    def create_submission(sequencescape_submission_parameters)
      ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
      ss.save
    end
  end
end
