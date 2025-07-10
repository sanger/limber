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

    # Validates that all wells with samples on the parent plate have a concentration value.
    # If any well is missing a concentration, adds an error and stops the process.
    # Otherwise, performs the standard plate transfer and updates QC results.
    #
    # @return [Boolean] false if validation fails, otherwise proceeds with transfer and QC update
    def create_plate_with_standard_transfer!
      # Check if the parent plate has wells with concentrations
      # First. take the wells with samples
      parent.wells.each do |well|
        if well.aliquots.sample.present? && well.latest_molarity.nil?
          errors.add(:base, "Well #{well.location} on the parent plate does not have a concentration value.")
        end
      end
      return false if errors.any?
      super { |child_plate| update_qc_results!(child_plate) }
    end

    # Returns the dilution factor from the purpose configuration.
    # Defaults to 10 if the configuration is missing or set to zero.
    #
    # @return [Integer] the dilution factor to use for calculations
    def dilution_factor
      dilution_factor = purpose_config['dilution_factor'] || 10
      dilution_factor.zero? ? 10 : dilution_factor
    end

    def update_qc_results!(child_plate)
      !Sequencescape::Api::V2::QcAssay.create!(qc_results: qc_assay(child_plate)).nil?
    end

    # Prepares QC assay data for each well on the plate.
    # Calculates the diluted molarity for each well using the dilution factor,
    # and returns an array of hashes containing QC result information.
    #
    # @return [Array<Hash>] QC assay results for all wells
    def qc_assay(child_plate)
      parent
        .wells
        .each_with_object([]) do |source_well, qc_results|
          well = child_plate.wells.detect { |child_well| child_well.location == source_well.location }
          next unless well
          diluted_concentration = source_well.latest_molarity.value.to_f / dilution_factor
          qc_results << { key: 'molarity', value: diluted_concentration, units: 'nM', uuid: well.uuid }
        end
    end
  end
end
