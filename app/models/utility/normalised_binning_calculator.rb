# frozen_string_literal: true

module Utility
  # Handles the Computations for Normalised Binning
  # Used by the Normalised Binned Plate and Presenter classes to handle the
  # normalisation, compute the bins and provide helpers on displaying
  # the bins on the child plate.
  class NormalisedBinningCalculator
    include ActiveModel::Model
    include Utility::CommonDilutionCalculations

    self.version = 'v1.0'

    attr_reader :config

    def initialize(config)
      @config = Utility::DilutionsConfig.new(config)
    end

    delegate :to_bigdecimal, :source_volume, :diluent_volume, :number_of_bins, :bins_template,
             :number_decimal_places, to: :config

    def normalisation_details(plate)
      plate.wells_in_columns.each_with_object({}) do |well, details|
        next if well.aliquots.blank?

        sample_conc      = to_bigdecimal(well.latest_concentration.value)
        vol_source_reqd  = compute_vol_source_reqd(sample_conc)
        vol_diluent_reqd = (config.target_volume - vol_source_reqd)
        amount           = (vol_source_reqd * sample_conc)
        dest_conc        = (amount / config.target_volume)

        details[well.location] = {
          'vol_source_reqd' => vol_source_reqd.round(number_decimal_places),
          'vol_diluent_reqd' => vol_diluent_reqd.round(number_decimal_places),
          'amount_in_target' => amount.round(number_decimal_places),
          'dest_conc' => dest_conc.round(number_decimal_places)
        }
      end
    end

    def compute_vol_source_reqd(sample_conc)
      # check calculated volume against minimum then maximum allowed volumes
      min_checked_vol_reqd = [config.target_amount / sample_conc, config.minimum_source_volume].max
      [min_checked_vol_reqd, config.target_volume].min
    end

    def compute_well_transfers(plate)
      norm_details = normalisation_details(plate)
      compute_well_transfers_hash(norm_details, plate.number_of_rows, plate.number_of_columns)
    end

    def compute_well_transfers_hash(norm_details, number_of_rows, number_of_columns)
      conc_bins = concentration_bins(norm_details)
      compression_reqd = compression_required?(conc_bins, number_of_rows, number_of_columns)
      build_transfers_hash(conc_bins, number_of_rows, compression_reqd)
    end

    def extract_destination_concentrations(transfer_hash)
      transfer_hash.values.each_with_object({}) do |dest_details, dest_hash|
        dest_hash[dest_details['dest_locn']] = dest_details['dest_conc'].to_f
      end
    end

    # Used by the plate presenter. Uses the concentration in the well and the plate purpose config
    # to work out the well bin colour and number of PCR cycles.
    def compute_presenter_bin_details(plate)
      well_amounts = compute_well_amounts(plate)
      compute_bin_details_by_well(well_amounts)
    end

    private

    # Sorts well locations into bins based on their amounts.
    def concentration_bins(norm_details)
      conc_bins = (1..number_of_bins).each_with_object({}) { |bin_number, bins_hash| bins_hash[bin_number] = [] }
      norm_details.each do |well_locn, details|
        amount = details['amount_in_target']
        bins_template.each_with_index do |bin_template, bin_index|
          next unless (bin_template['min']..bin_template['max']).cover?(amount)

          conc_bins[bin_index + 1] << { 'locn' => well_locn, 'details' => details }
          break
        end
      end
      conc_bins
    end

    # Builds a hash of transfers, including destination concentration information.
    def build_transfers_hash(bins, number_of_rows, compression_reqd)
      column = 0
      row = 0
      bins.values.each_with_object({}) do |bin, transfers_hash|
        next if bin.length.zero?

        # TODO: we may want to sort the bin here, e.g. by concentration
        bin.each do |well|
          src_locn = well['locn']
          details = well['details']
          transfers_hash[src_locn] = {
            'dest_locn' => WellHelpers.well_name(row, column),
            'dest_conc' => details['dest_conc'],
            'volume' => details['vol_source_reqd']
          }
          if row == (number_of_rows - 1)
            row = 0
            column += 1
          else
            row += 1
          end
        end
        unless compression_reqd
          row = 0
          column += 1
        end
      end
    end

    def compute_well_amounts(plate)
      plate.wells_in_columns.each_with_object({}) do |well, well_amounts|
        next if well.aliquots.blank?

        # concentration recorded is per microlitre, multiply by volume to get amount in ng in well
        well_amounts[well.location] = to_bigdecimal(well.latest_concentration.value) * config.target_volume
      end
    end
  end
end
