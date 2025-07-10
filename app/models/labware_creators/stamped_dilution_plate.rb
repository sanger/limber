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
    private

    # Validates that all wells with samples on the parent plate have a concentration value.
    # If any well is missing a concentration, adds an error and stops the process.
    # Otherwise, performs the standard plate transfer and updates QC results.
    #
    # @return [Boolean] false if validation fails, otherwise proceeds with transfer and QC update
    def create_plate_with_standard_transfer!
      validate_wells_with_aliquots_must_have_concentrations
      return false if errors.any?
      super do |child_plate|
        unless update_qc_results!(child_plate)
          errors.add(:base, 'Failed to update QC results for the child plate.')
          return false
        end
      end
    end

    # Check if the parent plate has wells with concentrations
    def validate_wells_with_aliquots_must_have_concentrations
      parent.wells.each do |well|
        if well.aliquots.sample.present? && well.latest_molarity.nil?
          errors.add(:base, "Well #{well.location} on the parent plate does not have a concentration value.")
        end
      end
    end

    # Returns the dilution factor from the purpose configuration.
    # Defaults to 10 if the configuration is missing or set to zero.
    #
    # @return [Integer] the dilution factor to use for calculations
    def dilution_factor
      dilution_factor = purpose_config['dilution_factor'] || 10
      dilution_factor.zero? ? 10 : dilution_factor
    end

    # Creates QC assay records for the given child plate by submitting the prepared QC assay data.
    # Returns true if the QC assay creation is successful.
    #
    # @param child_plate [Sequencescape::Api::V2::Plate] The plate for which QC results are being created
    # @return [Boolean] true if QC assay creation succeeds, false otherwise
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
