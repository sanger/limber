# frozen_string_literal: true

module Utility
  # Handles the Computations for Concentration Binning
  # Used by the Concentration Binning Plate and Presenter classes to handle the
  # binning configuration, compute the bins and provide helpers on displaying
  # the bins on the child plate.
  class ConcentrationBinningCalculator
    include ActiveModel::Model
    include Utility::CommonDilutionCalculations

    self.version = 'v1.0'

    # Calculates the well amounts from the plate well concentrations and a volume multiplication factor.
    def compute_well_amounts(plate, multiplication_factor)
      plate.wells_in_columns.each_with_object({}) do |well, well_amounts|
        next if well.aliquots.blank?

        # concentration recorded is per microlitre, multiply by volume to get amount in ng in well
        well_amounts[well.location] = well.latest_concentration.value.to_f * multiplication_factor
      end
    end

    def compute_well_transfers(parent_plate)
      well_amounts = compute_well_amounts(parent_plate, source_multiplication_factor)
      compute_well_transfers_hash(well_amounts, parent_plate.number_of_rows, parent_plate.number_of_columns)
    end

    def compute_well_transfers_hash(well_amounts, number_of_rows, number_of_columns)
      conc_bins = concentration_bins(well_amounts)
      compression_reqd = compression_required?(conc_bins, number_of_rows, number_of_columns)
      build_transfers_hash(conc_bins, number_of_rows, compression_reqd)
    end

    # This is used by the plate presenter.
    # It uses the amount in the well and the plate purpose binning config to work out the well bin colour
    # and number of PCR cycles.
    def compute_presenter_bin_details(plate)
      well_amounts = compute_well_amounts(plate, dest_multiplication_factor)
      compute_bin_details_by_well(well_amounts)
    end

    private

    # Sorts well locations into bins based on their amounts and the binning configuration.
    def concentration_bins(well_amounts)
      conc_bins = (1..number_of_bins).each_with_object({}) { |bin_number, bins_hash| bins_hash[bin_number] = [] }
      well_amounts.each do |well_locn, amount|
        bins_template.each_with_index do |bin_template, bin_index|
          next unless (config.bin_min(bin_template)...config.bin_max(bin_template)).cover?(amount)

          dest_conc = (amount / (source_volume + diluent_volume)).round(config.number_decimal_places)
          conc_bins[bin_index + 1] << { 'locn' => well_locn, 'dest_conc' => dest_conc.to_s }
          break
        end
      end
      conc_bins
    end

    # Build the transfers hash, cycling through the bins and their wells and locating them onto the
    # child plate.
    def build_transfers_hash(bins, number_of_rows, compression_reqd)
      binner = Binner.new(compression_reqd, number_of_rows)
      bins.values.each_with_object({}).with_index do |(bin, transfers_hash), bin_index_within_bins|
        next if bin.length.zero?

        # TODO: we may want to sort the bin here, e.g. by concentration
        bin.each_with_index do |well, well_index_within_bin|
          src_locn = well['locn']
          transfers_hash[src_locn] = {
            'dest_locn' => WellHelpers.well_name(binner.row, binner.column),
            'dest_conc' => well['dest_conc']
          }
          # work out what the next row and column will be
          finished = ((bin_index_within_bins == bins.size - 1) && (well_index_within_bin == bin.size - 1))
          binner.next_well_location(well_index_within_bin, bin.size) unless finished
        end
      end
    end
  end
end
