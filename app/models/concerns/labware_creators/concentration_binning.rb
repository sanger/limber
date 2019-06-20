# frozen_string_literal: true

# Binning by well concentration (ug/ul)
module LabwareCreators::ConcentrationBinning
  extend ActiveSupport::Concern

  require 'bigdecimal'

  class_methods do
    # Calculates the well amounts when working with source (parent) plate.
    def source_well_amounts(source_plate, binning_config)
      well_amounts = {}
      source_plate.wells.each do |well|
        # concentration recorded is per microlitre, multiply by volume to get amount in well
        well_amounts[well.location] = BigDecimal(well.latest_concentration.value * binning_config['source_volume'], 3).to_s
      end
      well_amounts # e.g. { 'A1': 23.1, etc. }
    end

    def source_plate_multiplication_factor(binning_config)
      BigDecimal(binning_config['source_volume'], 3)
    end

    def dest_plate_multiplication_factor(binning_config)
      BigDecimal(binning_config['source_volume'] + binning_config['diluent_volume'], 3)
    end

    # Calculates the well amounts from the plate well concentrations and a volume multiplication factor.
    def well_amounts(plate, multiplication_factor)
      well_amounts = {}
      plate.wells.each do |well|
        # concentration recorded is per microlitre, multiply by volume to get amount in well
        well_amounts[well.location] = BigDecimal(well.latest_concentration.value * multiplication_factor, 3).to_s
      end
      well_amounts # e.g. { 'A1': 23.1, etc. }
    end

    # Generates a hash of transfer requests for the binned wells.
    def compute_transfers(well_amounts, binning_config, number_of_rows, number_of_columns)
      # puts "well_amounts = #{well_amounts}"
      # puts "binning_config = #{binning_config}"
      # puts "number_of_rows = #{number_of_rows}"
      # puts "number_of_columns = #{number_of_columns}"
      bins = concentration_bins(well_amounts, binning_config)
      # puts "bins = #{bins}"
      compression_reqd = compression_required?(bins, number_of_rows, number_of_columns)
      # puts "compression_reqd = #{compression_reqd}"
      transfers_hash = build_transfers_hash(bins, number_of_rows, compression_reqd)
      transfers_hash # e.g. { 'A1': { dest_locn: 'B1', dest_amount: 23.1, dest_conc: 0.66 }  }
    end

    # TODO: this is used on creating the destination plate to set qc_result concentrations for the wells
    def destination_well_concentrations(transfers_hash)
      # refactor the transfers hash for destinations
      # find out what is required for a qc_assay (plate of wells) endpoint in sequencescape
      # { 'A1': 0.66, 'B1': 0.27, etc. }
      # write these to DB
    end

    # TODO: this is used on displaying the destination plate
    # It has the destination wells and their qc_result concentrations.
    # It needs to use the plate purpose binning config to work which bin each well is in and the colour.
    def generate_bin_colours_hash(dest_plate, binning_config)
      # well_amounts = {}
      # dest_plate.wells.each |well|
      #   well_amount = well.latest_concentration.value * (binning_config['source_volume'].to_f + binning_config['diluent_volume'].to_f
      #   well_amounts[well.location] = well_amount
      # end
      # well_colours = {}
      # well_amounts.each do |well_locn, amount|
      #   binning_config['bins'].each do |bin_config|
      #     bin_min = (bin_config['min'] || -1.0).to_f
      #     bin_max = (bin_config['max'] || Float::INFINITY).to_f

      #     if amount > bin_min && amount <= bin_max
      #       well_colours[well_locn] = bin_config['colour']
      #       break
      #     end
      #   end
      # end
      # well_colours
    end

    private

    # Sorts well locations into bins based on their amounts and the binning configuration.
    def concentration_bins(well_amounts, binning_config)
      number_bins = binning_config['bins'].size
      bins = {}

      (1..number_bins).each { |bin_number| bins[bin_number] = [] }
      well_amounts.each do |well_locn, amount|
        amount_bd = BigDecimal(amount, 3)
        source_vol_bd = BigDecimal(binning_config['source_volume'], 3)
        diluent_vol_bd = BigDecimal(binning_config['diluent_volume'], 3)
        dest_conc_bd = (amount_bd / (source_vol_bd + diluent_vol_bd)).round(3)
        binning_config['bins'].each_with_index do |bin_config, bin_index|
          bin_min = BigDecimal((bin_config['min'] || -1.0), 3)
          bin_max = BigDecimal((bin_config['max'] || 'Infinity'), 3)

          if BigDecimal(amount, 3) > bin_min && BigDecimal(amount, 3) <= bin_max
            bins[bin_index + 1] << { 'locn' => well_locn, 'amount' => amount.to_s, 'dest_conc' => dest_conc_bd.to_s }
            break
          end
        end
      end
      bins # e.g. { 1: [{ locn: 'A1', amount: 23.1, dest_conc: 0.66 },{  }, etc  ] }
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
      # puts "bins = #{bins}"
      # puts "number_of_rows = #{number_of_rows}"
      # puts "compression_reqd = #{compression_reqd}"
      transfers_hash = {}
      column = 0
      row = 0
      bins.each do |_bin_number, bin|
        # puts "bin = #{bin}"
        bin.each do |well|
          # puts "well = #{well}"
          src_locn = well['locn']
          # puts "src_locn = #{src_locn}"
          transfers_hash[src_locn] = {
            'dest_locn' => WellHelpers.well_name(row, column),
            'dest_amount' => well['amount'],
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
          column += 1 unless bin.length.zero?
        end
      end
      transfers_hash # e.g. { 'A1': { dest_locn: 'B1', dest_amount: 23.1, dest_conc: 0.66 }  }
    end
  end
end
