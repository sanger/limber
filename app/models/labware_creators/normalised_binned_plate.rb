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
  class NormalisedBinnedPlate < StampedPlate
    include LabwareCreators::RequireWellsWithConcentrations
    include LabwareCreators::GenerateQCResults

    validate :wells_with_aliquots_have_concentrations?
    validate :transfer_hash_present?

    def dilutions_calculator
      @dilutions_calculator ||= Utility::NormalisedBinningCalculator.new(dilutions_config)
    end

    private

    # Validation to check we have identified wells to transfer.
    # Plate must contain at least one well with a request for library preparation, in a state of pending.
    def transfer_hash_present?
      return if transfer_hash.present?

      msg = 'No wells in the parent plate have pending library preparation requests with the expected library type. Check your Submission.'
      errors.add(:parent, msg)
    end

    def transfer_request_attributes(child_plate)
      well_filter.filtered.map do |well, additional_parameters|
        request_hash(well, child_plate, additional_parameters)
      end.compact
    end

    def request_hash(source_well, child_plate, additional_parameters)
      return unless transfer_hash.key?(source_well.location)

      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect do |child_well|
          child_well.location == transfer_hash[source_well.location]['dest_locn']
        end&.uuid,
        'volume' => transfer_hash[source_well.location]['volume'].to_s
      }.merge(additional_parameters)
    end

    def transfer_hash
      @transfer_hash ||= dilutions_calculator.compute_well_transfers(parent)
    end
  end
end
