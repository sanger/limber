# frozen_string_literal: true

module LabwareCreators
  class MultiStampTubes < Base # rubocop:todo Style/Documentation, Metrics/ClassLength
    include LabwareCreators::CustomPage
    include CreatableFrom::TubeOnly

    attr_accessor :transfers, :parents

    class_attribute :request_filter, :transfers_layout, :transfers_creator, :target_rows, :target_columns, :source_tubes

    self.page = 'multi_stamp_tubes'
    self.aliquot_partial = 'standard_aliquot'
    self.request_filter = 'null'
    self.transfers_layout = 'null'
    self.transfers_creator = 'multi-stamp-tubes'
    self.attributes += [
      { transfers: [[:source_tube, :source_asset, :outer_request, :pool_index, { new_target: :location }]] }
    ]
    self.target_rows = 8
    self.target_columns = 12
    self.source_tubes = 96

    validates :transfers, presence: true

    def allow_tube_duplicates?
      params.fetch('allow_tube_duplicates', false)
    end

    def require_tube_passed?
      params.fetch('require_tube_passed', false)
    end

    def acceptable_purposes
      params.fetch('acceptable_purposes', [])
    end

    private

    def create_labware!
      create_and_build_submission
      return if errors.size.positive?

      @child =
        Sequencescape::Api::V2::PooledPlateCreation.create!(
          child_purpose_uuid: purpose_uuid,
          parent_uuids: parent_uuids,
          user_uuid: user_uuid
        ).child

      transfer_material_from_parent!

      yield(@child) if block_given?
      true
    end

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

    # Returns a list of parent tube uuids extracted from the transfers
    def parent_uuids
      transfers.pluck(:source_tube).uniq
    end

    def parent_tubes
      Sequencescape::Api::V2::Tube.find_all({ uuid: parent_uuids }, includes: 'receptacle,aliquots,aliquots.study')
    end

    def transfer_material_from_parent!
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes,
        user_uuid: user_uuid
      )
    end

    def transfer_request_attributes
      transfers.map { |transfer| request_hash(transfer) }
    end

    def source_tube_outer_request_uuid(tube)
      # Assumption: the requests we want will still be in state pending, and there will only be
      # one for the submission id we just created
      pending_reqs =
        tube.receptacle.requests_as_source.reject { |req| req.state == 'passed' || req.submission_id != @submission_id }

      # TODO: what if no requests remain? shouldn't happen if submission was built previously
      pending_reqs.first.uuid || nil
    end

    def request_hash(transfer)
      tube = Sequencescape::Api::V2::Tube.find_by(uuid: transfer[:source_tube])

      {
        source_asset: transfer[:source_asset],
        target_asset:
          @child.wells.detect { |child_well| child_well.location == transfer.dig(:new_target, :location) }&.uuid,
        outer_request: source_tube_outer_request_uuid(tube)
      }
    end

    # Retrieves the submission parameters
    #
    # Returns: a hash containing the submission parameters
    # Adds: errors if there is more than one submission specified
    def configured_params
      submission_options_from_config = purpose_config.submission_options

      # if there's more than one appropriate submission, we can't know which one to choose,
      # so don't create one.
      if submission_options_from_config.count > 1
        errors.add(:base, 'Expected only one submission')
        return
      end

      # otherwise, create a submission with params specified in the config
      submission_options_from_config.values.first
    end

    # Returns a list of parent tube uuids
    def asset_uuids
      parent_tubes.map { |tube| tube.receptacle.uuid }
    end

    # Autodetection looks at the Study and Project already linked to the aliquots and uses that.
    #
    # Otherwise, Project and Study can be specified explicitly on the Submission Template
    # (submission_parameters field) if autodetection is not appropriate (for instance in Cardinal,
    # where one tube will contain samples from multiple different studies).
    def autodetect_studies
      configured_params[:autodetect_studies] || false
    end

    def autodetect_projects
      configured_params[:autodetect_projects] || false
    end

    # Creates a submission in Sequencescape based on the parent tubes
    def create_submission_from_parent_tubes
      sequencescape_submission_parameters = {
        template_name: configured_params[:template_name],
        request_options: configured_params[:request_options],
        asset_groups: [{ asset_uuids:, autodetect_studies:, autodetect_projects: }],
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
end
