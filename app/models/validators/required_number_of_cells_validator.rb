# frozen_string_literal: true

module Validators
  # Displays a warning if the study-specific required number of cells option is
  # not configured for the studies on the plate. The value of the option is used
  # for calculating the required volume of a sample going into a pool by study
  # while generating the driver file. If the option is not configured, a default
  # value is used. This validator is used to alert the user that the default
  # value will be used unless the option is configured for the studies missing
  # the option.
  #
  # When the driver file is generated, the current value of the option for each
  # study is used (or the default if it is missing). Therefore, it is possible
  # for the user to configure the option after seeing the warning and download
  # the driver file again to use the correct value.
  class RequiredNumberOfCellsValidator < ActiveModel::Validator
    STUDIES_WITHOUT_REQUIRED_NUMBER_OF_CELLS =
      'The required number of cells is not configured for all studies ' \
        'going into pooling on this plate. If not provided, the default ' \
        'value 5000 will be used for the samples of the following studies: ' \
        '%s. This value can be configured by study in Sequencescape. If you ' \
        'edit the study with an appropriate value, please download the ' \
        'driver file again to get the updated volumes.'

    # Checks if the required number of cells is configured for all studies
    # going into pooling. If not, it adds an error message to the presenter,
    # which is displayed to the user as a warning. It does not prevent the
    # user proceeding with the pooling. The validation is applied only when
    # the labware is in the pending state.
    #
    # @param presenter [Object] the presenter object
    # @return [void]
    def validate(presenter)
      # Only validate in the pending state which is where pooling is relevant.
      return unless presenter.labware.state == 'pending'

      studies = source_studies_without_required_number_of_cells(presenter)
      return if studies.empty?

      formatted_string = format(STUDIES_WITHOUT_REQUIRED_NUMBER_OF_CELLS, studies.join(', '))
      presenter.errors.add(:required_number_of_cells, formatted_string)
    end

    private

    def source_studies(presenter)
      presenter
        .labware
        .wells
        .flat_map do |dest_well|
          dest_well.transfer_requests_as_target.flat_map do |transfer_req|
            transfer_req.source_asset.aliquots.flat_map(&:study)
          end
        end
        .uniq
    end

    def source_studies_without_required_number_of_cells(presenter)
      source_studies(presenter)
        .select { |study| study.poly_metadatum_by_key('scrna_core_pbmc_donor_pooling_required_number_of_cells').blank? }
        .map(&:name)
        .uniq
    end
  end
end
