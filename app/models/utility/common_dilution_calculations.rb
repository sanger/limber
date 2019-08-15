# frozen_string_literal: true

module Utility
  # Holds common functions used in other calculators.
  module CommonDilutionCalculations
    extend ActiveSupport::Concern

    included do
      class_attribute :version
    end

    attr_reader :config

    def initialize(config)
      @config = Utility::DilutionsConfig.new(config)
    end

    delegate :number_decimal_places, :source_volume, :diluent_volume, :number_of_bins, :bins_template,
             :source_multiplication_factor, :dest_multiplication_factor, to: :config

    # Constructs the qc_assays collection details for use when writing calculated concentrations
    # for the newly created child plate.
    def construct_dest_qc_assay_attributes(child_uuid, transfer_hash)
      dest_concs = extract_destination_concentrations(transfer_hash)
      dest_concs.map do |dest_locn, dest_conc|
        {
          'uuid' => child_uuid,
          'well_location' => dest_locn,
          'key' => 'concentration',
          'value' => dest_conc,
          'units' => 'ng/ul',
          'cv' => 0,
          'assay_type' => self.class.name.demodulize,
          'assay_version' => version
        }
      end
    end

    # Refactor the transfers hash to give destination concentrations
    def extract_destination_concentrations(transfers_hash)
      transfers_hash.values.each_with_object({}) do |dest_details, dest_hash|
        dest_hash[dest_details['dest_locn']] = dest_details['dest_conc']
      end
    end

    # Handles deternination of next well location for bins
    class Binner
      attr_accessor :row, :column

      def initialize(compression_reqd, number_of_rows)
        @compression_reqd = compression_reqd
        @number_of_rows = number_of_rows
        @row = 0
        @column = 0
        validate_initial_arguments
      end

      # Work out what the next well location will be.
      # This depends on whether we are in the last well of a bin, whether compression is required,
      # and whether we are in the last row of the plate and will need to start a new column.
      # NB. rows and columns are zero-based here.
      # def next_well_location(cur_row, cur_column, index_within_bin, bin_size)
      def next_well_location(index_within_bin, bin_size)
        validate_next_well_arguments(index_within_bin, bin_size)

        if index_within_bin == bin_size - 1
          # last well in bin, so next well location depends on whether compression is required
          @compression_reqd ? determine_next_available_location : reset_to_top_of_next_column
        else
          # there are more wells yet in this bin so continue
          determine_next_available_location
        end
      end

      private

      def validate_initial_arguments
        raise ArgumentError, 'compression_reqd should be a boolean' unless @compression_reqd.in? [true, false]

        raise ArgumentError, 'number_of_rows should be greater than zero' if @number_of_rows.nil? || @number_of_rows <= 0
      end

      def validate_next_well_arguments(index_within_bin, bin_size)
        raise ArgumentError, 'index_within_bin must be 0 or greater' if index_within_bin.nil? || index_within_bin.negative?

        raise ArgumentError, 'bin_size must be greater than 0' if bin_size.nil? || bin_size <= 0
      end

      # Next available location depends on whether we are in the last row on the plate.
      def determine_next_available_location
        if @row == (@number_of_rows - 1)
          reset_to_top_of_next_column
        else
          @row += 1
        end
      end

      # Reset location to top of the next column.
      def reset_to_top_of_next_column
        @row = 0
        @column += 1
      end
    end

    private

    # Determines whether compression is required, or if we can start a new column per bin.
    # This is preferred because the user is working in a special strip tube plate (part of reagent kit)
    # which will be split to different PCR blocks to run for different numbers of cycles.
    def compression_required?(bins, number_of_rows, number_of_columns)
      columns_reqd = bins.sum do |_bin_number, bin|
        bin.length.fdiv(number_of_rows).ceil
      end
      columns_reqd > number_of_columns
    end

    # Used by plate presenters for binned plates to draw the binned plate view with coloured
    # wells and numbers of pcr cycles displayed.
    def compute_bin_details_by_well(well_amounts)
      well_amounts.each_with_object({}) do |(well_locn, amount), well_colours|
        bins_template.each do |bin_template|
          next unless (bin_template['min']...bin_template['max']).cover?(amount)

          well_colours[well_locn] = {
            'colour' => bin_template['colour'],
            'pcr_cycles' => bin_template['pcr_cycles']
          }
          break
        end
      end
    end
  end
end
