# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of plates where the source plate wells are normalised but are not rearranged
  # on the target plate (stamped).
  # The normalisation goal is to have a specific amount of DNA in the target wells (e.g. 50ng).
  # This amount to be in a specific target volume (e.g. 20ul).
  # There is also a minimum volume of source to take *e.g. 0.2ul).
  # The highest concentrated samples will have the minimum volume taken and be topped up with diluent.
  # The lowest concentrated samples will take the maximum volume with no diluent.
  # Once the normalisation is calculated the target wells are stamped onto the target plate without
  # binning or rearrangement.
  class ConcentrationNormalisedPlate < StampedPlate
    include LabwareCreators::RequireWellsWithConcentrations
    include LabwareCreators::GenerateQcResults

    validate :wells_with_aliquots_have_concentrations?

    def dilutions_calculator
      @dilutions_calculator ||= Utility::ConcentrationNormalisationCalculator.new(dilutions_config)
    end

    private

    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' =>
          child_plate
            .wells
            .detect { |child_well| child_well.location == transfer_hash[source_well.location]['dest_locn'] }
            &.uuid,
        'volume' => transfer_hash[source_well.location]['volume'].to_s
      }.merge(additional_parameters)
    end

    def transfer_hash
      @transfer_hash ||= dilutions_calculator.compute_well_transfers(parent)
    end
  end
end
