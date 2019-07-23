# frozen_string_literal: true

module Utility
  # Handles the Computations for Fixed Normalisation plate creation.
  # Used by the Fixed Normalisation Plate class to handle ???
  class FixedNormalisationCalculator
    include ActiveModel::Model

    attr_reader :config

    def initialize(config)
      @config = Utility::FixedNormalisationConfig.new(config)
    end

    delegate :to_bigdecimal, :source_volume, :diluent_volume, :source_multiplication_factor,
             :dest_multiplication_factor, to: :config

    # Compute the well transfers hash from the parent plate
    def compute_well_transfers(parent_plate)
      well_amounts = compute_well_amounts(parent_plate, source_multiplication_factor)
      build_transfers_hash(well_amounts)
    end

    # Construct the qc assays array from the transfer hash
    def construct_dest_well_qc_assay_attributes(child_uuid, transfer_hash)
      dest_concs = compute_destination_concentrations(transfer_hash)
      dest_concs.map do |dest_locn, dest_conc|
        {
          'uuid' => child_uuid,
          'well_location' => dest_locn,
          'key' => 'concentration',
          'value' => dest_conc,
          'units' => 'ng/ul',
          'cv' => 0,
          'assay_type' => 'Calculated',
          'assay_version' => 'Fixed Normalisation'
        }
      end
    end

    # Calculates the well amounts (ng) from the plate well concentrations and a volume multiplication factor.
    def compute_well_amounts(plate, multiplication_factor)
      plate.wells_in_columns.each_with_object({}) do |well, well_amounts|
        next if well.aliquots.blank?

        # concentration recorded is ng per microlitre, multiply by volume to get amount in ng in well
        well_amounts[well.location] = to_bigdecimal(well.latest_concentration.value) * multiplication_factor
      end
    end

    # Build the well transfers hash from the well amounts
    def build_transfers_hash(well_amounts)
      well_amounts.each_with_object({}) do |(well_locn, amount), transfers_hash|
        dest_conc_bd = (amount / dest_multiplication_factor).round(3)
        transfers_hash[well_locn] = { 'dest_locn' => well_locn, 'dest_conc' => dest_conc_bd.to_s }
      end
    end

    # Refactor the transfers hash to give destination well concentrations
    def compute_destination_concentrations(transfers_hash)
      transfers_hash.values.each_with_object({}) do |dest_details, dest_hash|
        dest_hash[dest_details['dest_locn']] = dest_details['dest_conc']
      end
    end
  end
end
