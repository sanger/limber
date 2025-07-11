# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

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
      super { |child_plate| return update_qc_results!(child_plate) }
    end

    # Validates that all wells with samples (aliquots) on the parent plate have a concentration value.
    # If any such well is missing a concentration, its coordinate is added to the error message.
    #
    # @return [void]
    def validate_wells_with_aliquots_must_have_concentrations
      invalid_wells =
        parent
          .wells
          .each_with_object([]) do |well, erroneous_wells|
            # Add the well's coordinate if it contains a sample but has no concentration value
            erroneous_wells << well.coordinate if well.aliquots.sample.present? && well.latest_molarity.nil?
          end
      # Only add an error if there are invalid wells
      return unless invalid_wells.empty?
      errors.add(:base, "Wells #{invalid_wells.join(', ')} on the parent plate does not have a concentration value.")
    end

    # Returns the dilution factor from the purpose configuration.
    # Defaults to 10 if the configuration is missing or set to zero.
    #
    # @return [Integer] the dilution factor to use for calculations
    def dilution_factor
      dilution_factor = purpose_config['dilution']['factor'] || 10
      dilution_factor.zero? ? 10 : dilution_factor
    end

    # Creates QC assay records for the given child plate by submitting the prepared QC assay data.
    # Returns true if the QC assay creation is successful.
    #
    # @param child_plate [Sequencescape::Api::V2::Plate] The plate for which QC results are being created
    # @return [Boolean] true if QC assay creation succeeds, false otherwise
    def update_qc_results!(child_plate)
      Sequencescape::Api::V2::QcAssay.create!(qc_results: qc_assay(child_plate))
      true
    rescue StandardError => e
      Rails.logger.error("Error in updating QC results: #{e.message}")
      errors.add(:base, 'Failed to update the QC results...')
      false
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
          well = find_matching_well(child_plate, source_well)
          next unless well
          qc_results << build_qc_result_hash(source_well, well)
        end
    end

    # Finds the well in the child plate that matches the location of the source well.
    #
    # @param child_plate [Sequencescape::Api::V2::Plate] The child plate to search
    # @param source_well [Sequencescape::Api::V2::Well] The source well whose location is used for matching
    # @return [Sequencescape::Api::V2::Well, nil] The matching well in the child plate, or nil if not found
    def find_matching_well(child_plate, source_well)
      child_plate.wells.detect { |child_well| child_well.location == source_well.location }
    end

    # Builds a hash representing the QC result for a given source and child well.
    #
    # @param source_well [Sequencescape::Api::V2::Well] The well from the parent plate
    # @param well [Sequencescape::Api::V2::Well] The corresponding well from the child plate
    # @return [Hash] The QC result hash containing key, value, units, and uuid
    def build_qc_result_hash(source_well, well)
      {
        key: purpose_config['dilution']['type'] || 'molarity',
        value: source_well.latest_molarity.value.to_f / dilution_factor,
        units: purpose_config['dilution']['unit'] || 'nM',
        uuid: well.uuid
      }
    end
  end
end
