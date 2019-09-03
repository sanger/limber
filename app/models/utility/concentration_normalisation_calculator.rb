# frozen_string_literal: true

module Utility
  # Handles the Computations for Concentration Normalisation.
  # Used by the Concentration Normalised Plate class to handle the
  # normalisation processing.
  class ConcentrationNormalisationCalculator
    include ActiveModel::Model
    include Utility::CommonDilutionCalculations

    self.version = 'v1.0'

    def normalisation_details(plate)
      plate.wells_in_columns.each_with_object({}) do |well, details|
        next if well.aliquots.blank?

        sample_conc      = well.latest_concentration.value.to_f
        vol_source_reqd  = compute_vol_source_reqd(sample_conc)
        vol_diluent_reqd = (config.target_volume - vol_source_reqd)
        amount           = (vol_source_reqd * sample_conc)
        dest_conc        = (amount / config.target_volume)

        # NB. we do not round the destination concentration so the full number is written in the qc_results to avoid
        # rounding errors causing the presenter to display some wells as being in different bins.
        details[well.location] = {
          'vol_source_reqd' => vol_source_reqd.round(number_decimal_places),
          'vol_diluent_reqd' => vol_diluent_reqd.round(number_decimal_places),
          'amount_in_target' => amount.round(number_decimal_places),
          'dest_conc' => dest_conc
        }
      end
    end

    def compute_vol_source_reqd(sample_conc)
      # check calculated volume against minimum allowed volume
      min_checked_vol_reqd = [config.target_amount / sample_conc, config.minimum_source_volume].max
      # we don't want the diluent volume to be below 1ul (robot restriction), so we have to round the source
      # volume either to the maximum volume or to 1ul less than the maximum volume when in this range
      min_checked_vol_reqd = min_checked_vol_reqd.round(half: :down) if ((config.target_volume - 1.0)...config.target_volume).cover?(min_checked_vol_reqd)
      # check calculated volume against maximum allowed volume
      [min_checked_vol_reqd, config.target_volume].min
    end

    def compute_well_transfers(plate)
      norm_details = normalisation_details(plate)
      build_transfers_hash(norm_details)
    end

    private

    # Build the transfers hash, cycling through the bins and their wells and locating them onto the
    # child plate.
    def build_transfers_hash(norm_details)
      norm_details.each_with_object({}) do |(well_locn, details), transfers_hash|
        transfers_hash[well_locn] = {
          'dest_locn' => well_locn,
          'dest_conc' => details['dest_conc'].to_s,
          'volume' => details['vol_source_reqd'].to_s
        }
      end
    end
  end
end
