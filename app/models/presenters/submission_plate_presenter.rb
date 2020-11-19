# frozen_string_literal: true

module Presenters
  #
  # The StandardPresenter is used for the majority of plates. It shows a preview
  # of the plate itself, and permits state changes, well failures and child
  # creation when passed.
  #
  class SubmissionPlatePresenter < PlatePresenter
    include Presenters::Statemachine::Submission
    include Presenters::Statemachine::DoesNotAllowLibraryPassing
    include Presenters::StateChangeless

    self.summary_items = {
      'Barcode' => :barcode,
      'Number of wells' => :number_of_wells,
      'Plate type' => :purpose_name,
      'Current plate state' => :state,
      'Input plate barcode' => :input_barcode,
      'Created on' => :created_on
    }

    def each_submission_option
      purpose_config.submission_options.each do |button_text, options|
        submission_options = options.to_hash
        submission_options[:asset_groups] = asset_groups
        yield button_text, SequencescapeSubmission.new(submission_options)
      end
    end

    private

    def asset_groups
      @asset_groups ||= labware.wells
                               .reject(&:empty?)
                               .group_by(&:order_group)
                               .transform_values { |wells| wells.map(&:uuid) }
                               .values
    end
  end
end
