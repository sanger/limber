# frozen_string_literal: true

# This module contains validations for donor pooling.
module LabwareCreators::DonorPoolingValidator
  extend ActiveSupport::Concern

  included do
    validate :source_barcodes_must_be_entered
    validate :source_barcodes_must_be_different
    validate :source_plates_must_exist
    validate :wells_with_aliquots_must_have_donor_id
    validate :number_of_pools_must_not_exceed_configured
  end

  SOURCE_BARCODES_MUST_BE_ENTERED = 'should be entered, Please scan in all the required source plate barcodes.'

  SOURCE_BARCODES_MUST_BE_DIFFERENT = 'should not have the same barcode, please check you scanned all the plates.'

  SOURCE_PLATES_MUST_EXIST = 'not found, please check you scanned the correct source plates.'

  NUMBER_OF_POOLS_MUST_NOT_EXCEED_CONFIGURED =
    'calculated number of pools (%s) is higher than the number of pools ' \
      '(%s) configured. Please check you have scanned the correct set of ' \
      'source plates.'

  WELLS_WITH_ALIQUOTS_MUST_HAVE_DONOR_ID = 'wells missing donor_id sample metadata: %s'

  # Validates that at least one source barcode has been entered. If no barcodes
  # are entered, an error is added to the :source_barcodes attribute.
  #
  # @return [void]
  def source_barcodes_must_be_entered
    return if minimal_barcodes.size >= 1

    errors.add(:source_barcodes, SOURCE_BARCODES_MUST_BE_ENTERED)
  end

  # Validates that all source barcodes are unique. If any barcodes are
  # duplicated, an error is added to the :source_barcodes attribute.
  #
  # @return [void]
  def source_barcodes_must_be_different
    return if minimal_barcodes.size == minimal_barcodes.uniq.size

    errors.add(:source_barcodes, SOURCE_BARCODES_MUST_BE_DIFFERENT)
  end

  # Validates that all source plates corresponding to the minimal barcodes exist.
  # If the number of source plates does not match the number of minimal barcodes,
  # an error is added to the :source_plates attribute.
  #
  # @return [void]
  def source_plates_must_exist
    return if source_plates.size == minimal_barcodes.size

    errors.add(:source_plates, SOURCE_PLATES_MUST_EXIST)
  end

  # Validates that the number of calculated pools does not exceed the configured
  # number of pools. If the number of calculated pools is greater, an error is
  # added to the :source_plates attribute.
  #
  # @return [void]
  def number_of_pools_must_not_exceed_configured
    # Don't add this error if there are already errors about missing donor_ids.
    invalid_wells_hash = locations_with_missing_donor_id(source_plates)
    return if invalid_wells_hash.any?

    return if pools.size <= number_of_pools

    errors.add(:source_plates, format(NUMBER_OF_POOLS_MUST_NOT_EXCEED_CONFIGURED, pools.size, number_of_pools))
  end

  # Validates that all wells with aliquots must have a donor_id.
  # It uses the locations_with_missing_donor_id method to find any wells that are
  # missing a donor_id. If any such wells are found, it adds an error message to
  # the source_plates attribute, formatted with the barcodes of the plates and
  # the wells that are missing a donor_id.
  #
  # @return [void]
  def wells_with_aliquots_must_have_donor_id
    invalid_wells_hash = locations_with_missing_donor_id(source_plates)
    return if invalid_wells_hash.empty?

    formatted_string = invalid_wells_hash.map { |barcode, locations| "#{barcode}: #{locations.join(', ')}" }.join(' ')
    errors.add(:source_plates, format(WELLS_WITH_ALIQUOTS_MUST_HAVE_DONOR_ID, formatted_string))
  end

  private

  # Checks each well in each source plate for missing donor_id. Returns a hash
  # with keys as the barcodes of source plates and values as arrays of well
  # locations with missing donor_id. If a plate has no wells with missing
  # donor_id, it is not included in the returned hash. This method is used by
  # the wells_with_aliquots_must_have_donor_id method to generate an error message.
  #
  # @param source_plates [Array] An array of source plates to check.
  # @return [Hash] A hash mapping source plate barcodes to arrays of invalid wells.
  def locations_with_missing_donor_id(source_plates)
    source_plates.each_with_object({}) do |source_plate, hash|
      invalid_wells = source_plate.wells.select { |well| missing_donor_id?(well) }
      hash[source_plate.human_barcode] = invalid_wells.map(&:location) if invalid_wells.any?
    end
  end

  # Checks if a well is missing a donor_id. Returns false if the well has not
  # passed or if there is no aliquot. If there is an aliquot, it checks if the
  # associated sample_metadata has a donor_id. If the donor_id is missing, it
  # returns true. Otherwise, it returns false.
  #
  # @param well [Well] The well to check.
  # @return [Boolean] True if the well is missing a donor_id, false otherwise.
  def missing_donor_id?(well)
    return false unless well.passed?

    aliquot = well.aliquots&.first
    return false unless aliquot

    (aliquot.sample.sample_metadata.donor_id || '').to_s.strip.blank?
  end
end