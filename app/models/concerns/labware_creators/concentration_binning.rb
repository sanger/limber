# frozen_string_literal: true

# Binning by well concentration (ug/ul)
# These methods are used by the Concentration Binning Plate and Presenter classes to compute the bins and help when
# displaying them.
module LabwareCreators::ConcentrationBinning
  extend ActiveSupport::Concern

  require 'bigdecimal'

  # rubocop:disable Metrics/BlockLength
  class_methods do
    # Calculates the multiplication factor for the source (parent) plate
    def source_plate_multiplication_factor(binning_config)
      bd_value(binning_config['source_volume'])
    end

    # Calculates the multiplication factor for the destination (child) plate
    def dest_plate_multiplication_factor(binning_config)
      bd_value(binning_config['source_volume']) + bd_value(binning_config['diluent_volume'])
    end

    # Calculates the well amounts from the plate well concentrations and a volume multiplication factor.
    def compute_well_amounts(plate, multiplication_factor)
      plate.wells_in_columns.each_with_object({}) do |well, well_amounts|
        next if well.aliquots.blank?

        # concentration recorded is per microlitre, multiply by volume to get amount in well
        well_amount = bd_value(well.latest_concentration.value) * bd_value(multiplication_factor)
        well_amounts[well.location] = well_amount.to_s
      end
    end

    # Generates a hash of transfer requests for the binned wells.
    def compute_transfers(well_amounts, binning_config, number_of_rows, number_of_columns)
      bins = concentration_bins(well_amounts, binning_config)
      compression_reqd = compression_required?(bins, number_of_rows, number_of_columns)
      build_transfers_hash(bins, number_of_rows, compression_reqd)
    end

    # Refactor the transfers hash to give destination concentrations
    def compute_destination_concentrations(transfers_hash)
      transfers_hash.values.each_with_object({}) do |dest_details, dest_hash|
        dest_hash[dest_details['dest_locn']] = dest_details['dest_conc']
      end
    end

    # This is used by the plate presenter.
    # It uses the amount in the well and the plate purpose binning config to work out the well bin colour
    # and number of PCR cycles.
    def compute_presenter_bin_details(well_amounts, binning_config)
      well_amounts.each_with_object({}) do |(well_locn, amount), well_colours|
        binning_config['bins'].each do |bin_config|
          bin_min = bin_min(bin_config)
          bin_max = bin_max(bin_config)

          next unless bd_value(amount) > bin_min && bd_value(amount) <= bin_max

          well_colours[well_locn] = {
            'colour' => bin_config['colour'],
            'pcr_cycles' => bin_config['pcr_cycles']
          }
          break
        end
      end
    end

    private

    def bd_value(number)
      BigDecimal(number, 3)
    end

    def bin_min(bin_config)
      bd_value((bin_config['min'] || -1.0))
    end

    def bin_max(bin_config)
      bd_value((bin_config['max'] || 'Infinity'))
    end

    # Sorts well locations into bins based on their amounts and the binning configuration.
    def concentration_bins(well_amounts, binning_config)
      number_bins = binning_config['bins'].size
      bins = (1..number_bins).each_with_object({}) { |bin_number, bins_hash| bins_hash[bin_number] = [] }
      well_amounts.each do |well_locn, amount|
        amount_bd = bd_value(amount)
        source_vol_bd = bd_value(binning_config['source_volume'])
        diluent_vol_bd = bd_value(binning_config['diluent_volume'])
        dest_conc_bd = (amount_bd / (source_vol_bd + diluent_vol_bd)).round(3)
        binning_config['bins'].each_with_index do |bin_config, bin_index|
          bin_min = bin_min(bin_config)
          bin_max = bin_max(bin_config)

          next unless amount_bd > bin_min && amount_bd <= bin_max

          bins[bin_index + 1] << { 'locn' => well_locn, 'dest_conc' => dest_conc_bd.to_s }
          break
        end
      end
      bins
    end

    # Determines whether compression is required, or if we can start a new column per bin.
    # This is preferred because the user is working in a special strip tube plate (part of reagent kit)
    # which will be split to different PCR blocks to run for different numbers of cycles.
    def compression_required?(bins, number_of_rows, number_of_columns)
      columns_reqd = 0
      bins.each do |_bin_number, bin|
        columns_reqd += bin.length.fdiv(number_of_rows).ceil unless bin.length.zero?
      end
      columns_reqd > number_of_columns
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
          transfers_hash[src_locn] = {
            'dest_locn' => WellHelpers.well_name(row, column),
            'dest_conc' => well['dest_conc']
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
  end
  # rubocop:enable Metrics/BlockLength
end
