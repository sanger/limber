# frozen_string_literal: true

module LabwareCreators
  # This is an abstract class not intended to be used directly.
  # It holds the shared behaviour from its subclasses.
  # These creators require functionality to handle a partial submission of wells on their
  # parent plate, and use a well filter to select those wells with requests that have
  # the correct request type, library type and request state.
  # Each sub-class should override the dilutions_calculator.
  class PartialStampedPlate < StampedPlate
    include LabwareCreators::RequireWellsWithConcentrations
    include LabwareCreators::GenerateQcResults

    validate :wells_with_aliquots_must_have_concentrations
    validate :transfer_hash_must_be_present
    validate :number_of_transfers_must_match_number_of_filtered_wells

    # Override this method in sub-class to implement behaviour.
    def dilutions_calculator
      nil
    end

    private

    # The well filter will be used to identify the parent wells to be taken forward.
    # Filters on request type, library type and state.
    def well_filter
      @well_filter ||= WellFilterAllowingPartials.new(creator: self, request_state: 'pending')
    end

    # Returns the parent wells selected to be taken forward.
    def filtered_wells
      well_filter.filtered.each_with_object([]) { |well_filter_details, wells| wells << well_filter_details[0] }
    end

    # Validation to check we have identified wells to transfer.
    # Plate must contain at least one well with a request for library preparation, in a state of pending.
    def transfer_hash_must_be_present
      return if transfer_hash.present?

      msg =
        'No wells in the parent plate have pending library preparation requests with the expected library type. ' \
        'Check your Submission.'

      errors.add(:parent, msg)
    end

    # Validation to check number of filtered wells matches to final transfers hash produced
    def number_of_transfers_must_match_number_of_filtered_wells
      return if transfer_hash.length == filtered_wells.length

      msg = 'Number of filtered wells does not match number of well transfers'
      errors.add(:parent, msg)
    end

    # Override this method in sub-class if required.
    def request_hash(source_well, child_plate, additional_parameters)
      {
        source_asset: source_well.uuid,
        target_asset:
          child_plate
            .wells
            .detect { |child_well| child_well.location == transfer_hash[source_well.location]['dest_locn'] }
            &.uuid,
        volume: dilutions_calculator.source_volume.to_s
      }.merge(additional_parameters)
    end

    # Uses the calculator to generate the hash of transfers to be performed on the parent plate
    def transfer_hash
      @transfer_hash ||= dilutions_calculator.compute_well_transfers(parent, filtered_wells)
    end
  end
end
