# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of fixed normalised plate.
  # This type of plate has a source and diluent volume specified in the purpose configuration.
  # Wells are stamped across without any rearrangements.
  # The child well concentrations are calculated and written as qc_results on the plate.
  class FixedNormalisedPlate < StampedPlate
    include LabwareCreators::RequireWellsWithConcentrations
    include LabwareCreators::GenerateQCResults

    validate :wells_with_aliquots_have_concentrations?
    validate :transfer_hash_present?

    def dilutions_calculator
      @dilutions_calculator ||= Utility::FixedNormalisationCalculator.new(dilutions_config)
    end

    private

    def well_filter
      @well_filter ||= WellFilterAllowingPartials.new(creator: self)
    end

    # Validation to check we have identified wells to transfer.
    # Plate must contain at least one well with a request for library preparation, in a state of pending.
    def transfer_hash_present?
      return if transfer_hash.present?

      msg = 'No wells in the parent plate have pending library preparation requests with the expected library type. Check your Submission.'
      errors.add(:parent, msg)
    end

    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect do |child_well|
          child_well.location == transfer_hash[source_well.location]['dest_locn']
        end&.uuid,
        'volume' => dilutions_calculator.source_volume.to_s
      }.merge(additional_parameters)
    end

    def transfer_hash
      @transfer_hash ||= dilutions_calculator.compute_well_transfers(parent)
    end
  end
end
