module LabwareCreators::AutoSubmissionBehaviour
  # This module is included in labware creators that require
  # auto submission to Sequencescape.
  # It provides methods to create a submission and build it
  # based on the parent tubes.
  # It also provides a method to create a submission
  # in Sequencescape based on the parent tubes.
  # It is used in the create_labware! method of the labware creator.
  extend ActiveSupport::Concern

  def create_and_build_submission
    submission_created = create_submission_from_parent_tubes
    unless submission_created
      errors.add(:base, 'Failed to create submission')
      return
    end

    errors.add(:base, 'Failed to build submission') unless submission_built?
  end

  def submission_built?
    counter = 1
    while counter <= 6
      submission = Sequencescape::Api::V2::Submission.where(uuid: @submission_uuid).first
      if submission.building_in_progress?
        sleep(5)
        counter += 1
      else
        @submission_id = submission.id
        return true
      end
    end
    false
  end

  private

  # Creates a submission in Sequencescape based on the parent tubes
  def create_submission_from_parent_tubes
    sequencescape_submission_parameters = {
      template_name: configured_params[:template_name],
      request_options: configured_params[:request_options],
      asset_groups: [
        { assets: asset_uuids, autodetect_studies: autodetect_studies, autodetect_projects: autodetect_projects }
      ],
      api: api,
      user: user_uuid
    }

    create_submission(sequencescape_submission_parameters)
  end

  # Creates a submission in Sequencescape
  #
  # Parameters:
  # - sequencescape_submission_parameters: a hash containing the parameters for the submission
  #
  # Returns: true if submission created, false otherwise
  # Sets: @submission_uuid if submission created
  # Adds: errors if submission not created
  def create_submission(sequencescape_submission_parameters)
    ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
    submission_created = ss.save

    if submission_created
      @submission_uuid = ss.submission_uuid
      return true
    end

    errors.add(:base, ss.errors.full_messages)
    false
  end
end
