# frozen_string_literal: true

module Utility
  #
  # This module holds common functions used by other utility calculators.
  #
  module CommonDilutionCalculations
    extend ActiveSupport::Concern

    #
    # Each calculator maintains a version number that gets written into the qc
    # assay records.
    #
    included { class_attribute :version }

    attr_reader :config

    #
    # The calculators all use a common configuration structure stored on the
    # plate purpose.
    #
    # @param config [hash] The relevant section from the plate purpose configuration.
    #
    def initialize(config)
      @config = Utility::DilutionsConfig.new(config)
    end

    delegate :number_decimal_places,
             :source_volume,
             :diluent_volume,
             :number_of_bins,
             :bins_template,
             :source_multiplication_factor,
             :dest_multiplication_factor,
             to: :config

    #
    # Creates a hash of well normalisation details for a plate used when generating
    # the well transfers and qc assays.
    #
    # @param wells [Wells] The source wells being normalised.
    #
    # @return [hash] The well details hash containing calculated normalisation values.
    #
    def normalisation_details(wells) # rubocop:todo Metrics/AbcSize
      # sort on well coordinate to ensure wells are in plate column order
      wells
        .sort_by(&:coordinate)
        .each_with_object({}) do |well, details|
          # skip empty wells
          next if well.aliquots.blank?

          # check for well concentration value present
          if well.latest_concentration.blank?
            errors.add(:base, "Well #{well.location} does not have a concentration, cannot calculate amount in well")
            next
          end

          sample_conc = well.latest_concentration.value.to_f
          vol_source_reqd = compute_vol_source_reqd(sample_conc)
          vol_diluent_reqd = (config.target_volume - vol_source_reqd)
          amount = (vol_source_reqd * sample_conc)
          dest_conc = (amount / config.target_volume)

          # NB. we do not round the destination concentration so the full number is written
          # in the qc_results to avoid rounding errors causing the presenter to display some
          # wells as being in different bins.
          details[well.location] = {
            'vol_source_reqd' => vol_source_reqd.round(number_decimal_places),
            'vol_diluent_reqd' => vol_diluent_reqd.round(number_decimal_places),
            'amount_in_target' => amount.round(number_decimal_places),
            'dest_conc' => dest_conc
          }
        end
    end

    #
    # Computes the volume of source material required for normalisation based on the sample
    # concentration and attributes from the purpose configuration (target amount and volume,
    # minimum source volume).
    # Includes checks for minimum source volume and rounding for low diluent volumes due to liquid
    # handler robot restrictions.
    #
    # @param sample_conc [float] The concentration of the source sample in ng/ul
    #
    # @return [float] The volume of the source required in ul.
    #
    def compute_vol_source_reqd(sample_conc)
      calculated_raw_volume = config.target_amount / sample_conc

      # adjust the calculated volume to the maximum permissible for samples with very weak concentrations
      max_adj_volume = [calculated_raw_volume, config.minimum_source_volume].max

      # the robot cannot accept a diluent volume of less than 1ul, so this section adjusts the transfer
      # volume to prevent that when required
      transfer_volume =
        if ((config.target_volume - 1.0)...config.target_volume).cover?(max_adj_volume)
          max_adj_volume.round(half: :down)
        else
          max_adj_volume
        end

      # adjust the transfer volume to the minimum permissible for samples with very strong concentrations
      [transfer_volume, config.target_volume].min
    end

    #
    # Constructs the qc_assays collection details for use when writing calculated concentrations
    # for the newly created child plate.
    #
    # @param child_uuid [string] The uuid of the child plate being transferred into.
    # @param transfer_hash [hash] The transfers hash from which we extract the destination concentrations.
    #
    # @return [array] An array of qc assay details for the child plate, ready to send via Api to sequencescape.
    #
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

    #
    # Refactor the transfers hash to give destination concentrations
    #
    # @param transfer_hash [hash] The transfer details.
    #
    # @return [hash] A refactored hash of well concentrations.
    #
    def extract_destination_concentrations(transfer_hash)
      transfer_hash
        .values
        .each_with_object({}) do |dest_details, dest_hash|
          dest_hash[dest_details['dest_locn']] = dest_details['dest_conc']
        end
    end

    #
    # Class used by calculators that perform binning of wells according to concentration.
    # Handles the determination of the next well location for bins.
    #
    class Binner
      attr_accessor :row, :column

      #
      # Sets up an instance of the Binner class for a plate.
      #
      # @param compression_reqd [bool] Whether the binning should be compressed, or start each
      # new bin in a new column. Depends on number of bins and wells containing aliquots on the
      # plate.
      # @param number_of_rows [int] Number of rows on the plate.
      #
      def initialize(compression_reqd, number_of_rows)
        @compression_reqd = compression_reqd
        @number_of_rows = number_of_rows
        @row = 0
        @column = 0
        validate_initial_arguments
      end

      #
      # Work out what the next well location will be.
      # This depends on whether we are in the last well of a bin, whether compression is required,
      # and whether we are in the last row of the plate and will need to start a new column.
      # NB. rows and columns are zero-based here.
      #
      # @param index_within_bin [int] The index of the well within the current bin.
      # @param bin_size [int] The number of wells in the bin.
      #
      # @return nothing Sets the next row and column in the Binner instance.
      #
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
        raise ArgumentError, 'number_of_rows should be greater than zero' if @number_of_rows.to_i <= 0
      end

      def validate_next_well_arguments(index_within_bin, bin_size)
        if index_within_bin.nil? || index_within_bin.negative?
          raise ArgumentError, 'index_within_bin must be 0 or greater'
        end

        raise ArgumentError, 'bin_size must be greater than 0' if bin_size.nil? || bin_size <= 0
      end

      #
      # Next available location depends on whether we are in the last row on the plate.
      #
      def determine_next_available_location
        if @row == (@number_of_rows - 1)
          reset_to_top_of_next_column
        else
          @row += 1
        end
      end

      #
      # Reset location to top of the next column.
      #
      def reset_to_top_of_next_column
        @row = 0
        @column += 1
      end
    end

    #
    # Class used by calculators that need to compress wells to top left.
    # Handles the determination of the next well location.
    #
    class Compressor
      attr_accessor :row, :column

      #
      # Sets up an instance of the Compressor class for a plate.
      #
      # @param number_of_rows [int] Number of rows on the plate.
      #
      def initialize(number_of_rows)
        @number_of_rows = number_of_rows
        @row = 0
        @column = 0
        validate_initial_arguments
      end

      #
      # Work out what the next well location will be.
      # This depends on whether we are in the last row of the plate and will need to start a new column.
      # NB. rows and columns are zero-based here.
      #
      # @return nothing Sets the next row and column in the Compressor instance.
      #
      def next_well_location
        determine_next_available_location
      end

      private

      def validate_initial_arguments
        raise ArgumentError, 'number_of_rows should be greater than zero' if @number_of_rows.to_i <= 0
      end

      #
      # Next available location depends on whether we are in the last row on the plate.
      #
      def determine_next_available_location
        if @row == (@number_of_rows - 1)
          reset_to_top_of_next_column
        else
          @row += 1
        end
      end

      #
      # Reset location to top of the next column.
      #
      def reset_to_top_of_next_column
        @row = 0
        @column += 1
      end
    end

    private

    #
    # Determines whether compression is required, or if we can start a new column per bin.
    # New columns are preferred because the user is working in a special strip tube plate
    # (part of reagent kit) which will be split to different PCR blocks to run for different
    # numbers of cycles.
    #
    # @param bins [hash] The hash of bin arrays of wells.
    # @param number_of_rows [int] The number of rows on the plate.
    # @param number_of_columns [int] The number of columns on the plate.
    #
    # @return [bool] Whether compression is required.
    #
    def compression_required?(bins, number_of_rows, number_of_columns)
      columns_reqd = bins.sum { |_bin_number, bin| bin.length.fdiv(number_of_rows).ceil }
      columns_reqd > number_of_columns
    end

    #
    # Used by plate presenters for binned plates to draw the binned plate view with coloured
    # wells and numbers of pcr cycles displayed.
    #
    # @param well_amounts [hash] Amounts in each well in ng.
    #
    # @return [hash] Colours and number of pcr cycles for each well.
    #
    def compute_bin_details_by_well(well_amounts)
      well_amounts.each_with_object({}) do |(well_locn, amount), well_colours|
        bins_template.each do |bin_template|
          next unless (bin_template['min']...bin_template['max']).cover?(amount)

          well_colours[well_locn] = { 'colour' => bin_template['colour'], 'pcr_cycles' => bin_template['pcr_cycles'] }
          break
        end
      end
    end
  end
end
