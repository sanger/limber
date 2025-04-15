# frozen_string_literal: true
require_dependency 'labware_creators'

module LabwareCreators
  # Creates a new plate of the specified purpose and transfers material
  # across in a direct stamp. (ie. The location of a sample on the source plate
  # is the same as the location on the destination plate.)
    class PlateWithAutoSubmission < StampedPlate
    def create_labware!
      create_and_build_submission
      return if errors.size.positive?

      create_plate_with_standard_transfer!
      yield(@child) if block_given?
      true
    end

    def create_and_build_submission
      submission_created = create_submission_from_parent_plates
      unless submission_created
        errors.add(:base, 'Failed to create submission')
        return
      end

      errors.add(:base, 'Failed to build submission') unless submission_built?
    end

    def create_plate_with_standard_transfer!
      # binding.pry
      plate_creation = create_plate_from_parent!
      @child = plate_creation.child
      # binding.pry
      transfer_material_from_parent!(@child.uuid)
      yield(@child) if block_given?
      after_transfer!
      true
    end



    def submission_built? # rubocop:disable Metrics/MethodLength
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

    def autodetect_studies
      configured_params[:autodetect_studies] || false
    end

    def autodetect_projects
      configured_params[:autodetect_projects] || false
    end

    def asset_groups
      @asset_groups ||=
        labware
          .wells
          .compact_blank
          .group_by(&:order_group)
          .map { |_, wells| { assets: wells.map(&:uuid), autodetect_studies: true, autodetect_projects: true } }
    end
    # Creates a submission in Sequencescape based on the parent plates
    def create_submission_from_parent_plates
      sequencescape_submission_parameters = {
        template_name: configured_params[:template_name],
        request_options: configured_params[:request_options],
        asset_groups: asset_groups,
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

    # def transfer_request_attributes(child_plate)
    #   # binding.pry
    #   val = well_filter.filtered.map { |well, additional_parameters| request_hash(well, child_plate, additional_parameters) }
    #   # binding.pry
    #   val
    # end

  end
end
