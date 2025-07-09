# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

# TODO: Here, we need to find the parent well concentrations,
# read from the configurations the dilution factor,
# and then create the child plate with the diluted concentrations.
module LabwareCreators
  # Simply creates a new plate of the specified purpose and transfers material
  # across in a direct stamp. (ie. The location of a sample on the source plate
  # is the same as the location on the destination plate.)
  class StampedDilutionPlate < StampedPlate
    PLATE_INCLUDES =
      'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'

    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PLATE_INCLUDES, uuid: parent_uuid)
    end

    private

    # Overriding the create_plate_with_standard_transfer! method for validation and
    # custom behaviour specific to dilution plates.
    def create_plate_with_standard_transfer!
      # Check if the parent plate has wells with concentrations
      # First. take the wells with samples
      parent.wells.each do |well|
        if well.aliquots.sample.present? && well.latest_concentration.nil?
          errors.add(:base, "Well #{well.location} on the parent plate does not have a concentration value.")
        end
      end
      super
    end

    def dilution_factor
      dilution_factor = purpose_config['dilution_factor'] || 10
      dilution_factor.zero? ? 10 : dilution_factor
    end

    def request_hash(source_well, child_plate, additional_parameters)
      child_well = child_plate.wells.detect { |child_well| child_well.location == source_well.location }
      if child_well
        diluted_conc = source_well.latest_concentration.value.to_f / dilution_factor
        return(
          { source_asset: source_well.uuid, target_asset: child_well.uuid, concentration: diluted_conc }.merge(
            additional_parameters
          )
        )
      end
      { source_asset: source_well.uuid, target_asset: child_well&.uuid }.merge(additional_parameters)
    end
  end
end
