# frozen_string_literal: true

module Presenters
  #
  # This version of the PcrCyclesBinnedPlatePresenter fetches metadata from
  # the wells.
  #
  class PcrCyclesBinnedPlateUsingWellMetadataPresenter < PcrCyclesBinnedPlatePresenterBase
    CURRENT_PLATE_INCLUDES = 'wells.aliquots,wells.qc_results'

    def current_plate_includes
      CURRENT_PLATE_INCLUDES
    end

    private

    # This version of well details fetches the pcr cycles from the well metadata
    def well_details
      # For each well with aliquots on the plate select the pcr cycles metadata
      # { 'A1' => { 'pcr_cycles' => 16 }, 'B1' => etc. }
      @well_details ||=
        current_plate
          .wells
          .each_with_object({}) do |well, details|
          next if well.aliquots.empty?

          # Should be a value by this point in order to have calculated the binning
          pcr_cycles = well.attributes['pcr_cycles'] || nil
          raise "No pcr_cycles value found on well #{well.location}" if pcr_cycles.nil?

          details[well.location] = { 'pcr_cycles' => pcr_cycles }
        end
    end
  end
end
