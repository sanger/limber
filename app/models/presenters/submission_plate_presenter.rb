# frozen_string_literal: true

module Presenters
  #
  # The SubmissionPlatePresenter is used when plates enter the process with no
  # assigned pipeline. It presents the user with a selection of workflows,
  # and allows them to generate corresponding Sequencescape submissions. Once
  # these submissions are passed, the plate behaves like a standard stock plate.
  #
  # Submission options are defined by the submission_options config in the
  # purposes/*.yml file. Structure is:
  # <button text>:
  #   template_name: <submission template name>
  #   request_options:
  #     <request_option_key>: <request_option_value>
  #     ...
  class SubmissionPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Submission
    include Presenters::Statemachine::DoesNotAllowLibraryPassing
    include Presenters::StateChangeless

    self.style_class = 'stock'

    self.summary_items = {
      'Barcode' => :barcode,
      'Number of wells' => :number_of_wells,
      'Plate type' => :purpose_name,
      'Current plate state' => :state,
      'Input plate barcode' => :input_barcode,
      'Created on' => :created_on
    }

    # Is a new argument for the .new(); is this needed to be defined or will it work?
    attr_reader :additional_labwares

    def each_submission_option
      purpose_config.submission_options.each do |button_text, options|
        submission_options = options.to_hash
        submission_options[:asset_groups] = asset_groups
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
      return asset_groups_including_additional_labwares if additional_labwares
      # TODO: this would need to include all 4 plates, not just 1.
      @asset_groups ||= labware.wells
                               .reject(&:empty?)
                               .group_by(&:order_group)
                               .map do |_, wells|
                                 { assets: wells.map(&:uuid), autodetect_studies_projects: true }
                               end
    end

    def _asset_groups_including_additional_labwares
      @asset_groups ||= [labware, additional_labwares].flatten
                               .map(&:wells).flatten
                               .reject(&:empty?)
                               .group_by(&:order_group)
                               .map do |_, wells|
                                 { assets: wells.map(&:uuid), autodetect_studies_projects: true }
                               end
    end
  end
end
