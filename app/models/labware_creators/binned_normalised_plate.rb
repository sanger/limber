# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of plates where the source plate wells are normalised and rearranged
  # by bins onto the target plate.
  # The normalisation goal is to have a specific amount of DNA in the target wells (e.g. 50ng).
  # This amount to be in a specific target volume (e.g. 20ul).
  # There is also a minimum volume of source to take *e.g. 0.2ul).
  # The highest concentrated samples will have the minimum volume taken and be topped up with diluent.
  # The lowest concentrated samples will take the maximum volume with no diluent.
  # Once the normalisation is calculated the target wells are arranged according to bins of
  # total amount present, and different numbers of pcr cycles assigned to each bin to attempt
  # to further normalise the samples.
  class BinnedNormalisedPlate < StampedPlate
    validate :wells_with_aliquots_have_concentrations?

    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(
        'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type',
        uuid: parent_uuid
      )
    end

    # Validate that any wells with aliquots have associated qc_result concentration values.
    def wells_with_aliquots_have_concentrations?
      concs_missing = wells_with_missing_concs
      return if concs_missing.size.zero?

      msg = 'wells missing a concentration (have you uploaded concentrations via QuantHub?):'
      errors.add(:parent, "#{msg} #{concs_missing.join(', ')}")
    end

    # The configuration from the plate purpose.
    def binned_norm_config
      purpose_config.fetch(:binned_normalisation)
    end

    def binned_norm_calculator
      @binned_norm_calculator ||= Utility::BinnedNormalisationCalculator.new(binned_norm_config)
    end

    private

    def wells_with_missing_concs
      parent.wells.each_with_object([]) do |well, concs_missing|
        next if well.aliquots.blank?

        concs_missing << well.location if well.latest_concentration.nil?
      end
    end

    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect do |child_well|
          child_well.location == transfer_hash[source_well.location]['dest_locn']
        end&.uuid,
        'volume' => transfer_hash[source_well.location]['volume'].to_s
      }.merge(additional_parameters)
    end

    def transfer_hash
      @transfer_hash ||= compute_well_transfers
    end

    def dest_well_qc_attributes
      @dest_well_qc_attributes ||= binned_norm_calculator.construct_dest_well_qc_assay_attributes(child.uuid, transfer_hash)
    end

    def compute_well_transfers
      binned_norm_calculator.compute_well_transfers(parent)
    end

    def after_transfer!
      Sequencescape::Api::V2::QcAssay.create(
        qc_results: dest_well_qc_attributes
      )
    end
  end
end
