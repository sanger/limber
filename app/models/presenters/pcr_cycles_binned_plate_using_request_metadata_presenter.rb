# frozen_string_literal: true

module Presenters
  #
  # This version of the PcrCyclesBinnedPlatePresenter fetches metadata from
  # the Request poly_metadata.
  #
  class PcrCyclesBinnedPlateUsingRequestMetadataPresenter < PcrCyclesBinnedPlatePresenterBase
    # include Presenters::Statemachine::Standard

    CURRENT_PLATE_INCLUDES = 'wells.aliquots,wells.qc_results,wells.aliquots.request.poly_metadata'

    def current_plate_includes
      CURRENT_PLATE_INCLUDES
    end

    private

    # This version of well details fetches the pcr cycles from the request poly_metadata
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def well_details
      # For each well with aliquots on the plate select the pcr cycles metadata
      # { 'A1' => { 'pcr_cycles' => 16 }, 'B1' => etc. }
      @well_details ||=
        current_plate
          .wells
          .each_with_object({}) do |well, details|
          next if well.aliquots.empty?

          # Should be a value by this point in order to have calculated the binning
          # NB. poly_metadata are stored as strings so need to convert to integer
          pcr_cycles =
            well.aliquots.first.request.poly_metadata.find { |md| md.key == 'pcr_cycles' }&.value.to_i || nil # rubocop:todo Lint/UselessOr
          raise "No pcr_cycles metadata found for well #{well.location}" if pcr_cycles.nil?

          details[well.location] = { 'pcr_cycles' => pcr_cycles }
        end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  end
end
