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

    delegate :to_bigdecimal, :number_decimal_places, :source_volume, :diluent_volume, :number_of_bins, :bins_template,
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
          next unless (bin_template['min']..bin_template['max']).cover?(amount)

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
