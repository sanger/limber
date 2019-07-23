# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of ?.
  class BinnedNormalisedPlate < StampedPlate
    # validate :wells_with_aliquots_have_concentrations?

    # def parent
    #   @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(
    #     'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type',
    #     uuid: parent_uuid
    #   )
    # end

    # # Validate that any wells with aliquots have associated qc_result concentration values.
    # def wells_with_aliquots_have_concentrations?
    #   concs_missing = wells_with_missing_concs
    #   return if concs_missing.size.zero?

    #   msg = 'wells missing a concentration (have you uploaded concentrations via QuantHub?):'
    #   errors.add(:parent, "#{msg} #{concs_missing.join(', ')}")
    # end

    # # The configuration from the plate purpose.
    # def binning_config
    #   purpose_config.fetch(:concentration_binning)
    # end

    #   :binned_normalisation:
    # - target_amount_ng: 50
    #   target_volume_ul: 20
    #   minimum_source_volume_ul: 0.2
    #   bins:
    #   - colour: 1
    #     pcr_cycles: 16
    #     max: 25
    #   - colour: 2
    #     pcr_cycles: 14
    #     min: 25

    # def bin_calculator
    #   @bin_calculator ||= Utility::ConcentrationBinningCalculator.new(binning_config)
    # end

    # private

    # def wells_with_missing_concs
    #   parent.wells.each_with_object([]) do |well, concs_missing|
    #     next if well.aliquots.blank?

    #     concs_missing << well.location if well.latest_concentration.nil?
    #   end
    # end

    # def request_hash(source_well, child_plate, additional_parameters)
    #   {
    #     'source_asset' => source_well.uuid,
    #     'target_asset' => child_plate.wells.detect do |child_well|
    #       child_well.location == transfer_hash[source_well.location]['dest_locn']
    #     end&.uuid,
    #     'volume' => binning_config['source_volume']
    #   }.merge(additional_parameters)
    # end

    # def transfer_hash
    #   @transfer_hash ||= compute_well_transfers
    # end

    # def destination_concentrations_hash
    #   @destination_concentrations_hash ||= bin_calculator.compute_destination_concentrations(transfer_hash)
    # end

    # def dest_well_qc_attributes
    #   @dest_well_qc_attributes ||= compute_dest_well_qc_assay_attributes
    # end

    # def compute_well_transfers
    #   bin_calculator.compute_well_transfers(parent)
    # end

    # def compute_dest_well_qc_assay_attributes
    #   destination_concentrations_hash.map do |dest_locn, dest_conc|
    #     {
    #       'uuid' => child.uuid,
    #       'well_location' => dest_locn,
    #       'key' => 'concentration',
    #       'value' => dest_conc,
    #       'units' => 'ng/ul',
    #       'cv' => 0,
    #       'assay_type' => 'Calculated',
    #       'assay_version' => 'Binning'
    #     }
    #   end
    # end

    # def after_transfer!
    #   Sequencescape::Api::V2::QcAssay.create(
    #     qc_results: dest_well_qc_attributes
    #   )
    # end
  end
end
