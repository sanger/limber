# frozen_string_literal: true

# This module contains validations for donor pooling.
module LabwareCreators::DonorPoolingValidator
  extend ActiveSupport::Concern

  included do
    validate :source_barcodes_must_be_entered
    validate :source_barcodes_must_be_different
    validate :source_plates_must_exist
    validate :wells_with_aliquots_must_have_donor_id
    validate :wells_with_aliquots_must_have_cell_count
    validate :validate_pools_can_be_built
  end

  SOURCE_BARCODES_MUST_BE_ENTERED = 'At least one source plate must be scanned.'

  SOURCE_BARCODES_MUST_BE_DIFFERENT = 'You must not scan the same barcode more than once.'

  SOURCE_PLATES_MUST_EXIST =
    'Source plates not found: %s. ' \
    'Please check you scanned the correct source plates. '

  WELLS_WITH_ALIQUOTS_MUST_HAVE_DONOR_ID =
    'All samples must have the donor_id specified. ' \
    'Wells missing donor_id (on sample metadata): %s'

  WELLS_WITH_ALIQUOTS_MUST_HAVE_CELL_COUNT =
    'All wells must have cell count data unless they are failed. ' \
    'Wells missing cell count data: %s'

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

    formatted_string = (minimal_barcodes - source_plates.map(&:human_barcode)).join(', ')

    errors.add(:source_plates, format(SOURCE_PLATES_MUST_EXIST, formatted_string))
  end

  # Validates that all wells with aliquots must have a donor_id.
  # It uses the locations_with_missing_donor_id method to find any wells that are
  # missing a donor_id. If any such wells are found, it adds an error message to
  # the source_plates attribute, formatted with the barcodes of the plates and
  # the wells that are missing a donor_id.
  #
  # @return [void]
  def wells_with_aliquots_must_have_donor_id
    invalid_wells_hash = locations_with_missing_donor_id
    return if invalid_wells_hash.empty?

    formatted_string = formatted_invalid_wells_hash(invalid_wells_hash)
    errors.add(:source_plates, format(WELLS_WITH_ALIQUOTS_MUST_HAVE_DONOR_ID, formatted_string))
  end

  # Validates that wells with aliquots have a latest_live_cell_count. It uses
  # the locations_with_missing_cell_count method to find any wells that are
  # missing a cell count. If any such wells are found, it adds an error message
  # to the source_plates attribute, formatted with the barcodes of the plates
  # and the wells that are missing a cell count. Note that the well filter
  # already excludes failed wells. This validation ensures that all wells with
  # aliquots have a cell count unless they are failed.
  #
  # @return [void]
  def wells_with_aliquots_must_have_cell_count
    invalid_wells_hash = locations_with_missing_cell_count
    return if invalid_wells_hash.empty?

    formatted_string = formatted_invalid_wells_hash(invalid_wells_hash)
    errors.add(:source_plates, format(WELLS_WITH_ALIQUOTS_MUST_HAVE_CELL_COUNT, formatted_string))
  end

  private

  # Checks each source well for pooling for missing donor_id. Returns a hash
  # with keys as the barcodes of source plates and values as arrays of well
  # locations with missing donor_id. If a plate has no wells with missing
  # donor_id, it is not included in the returned hash. This method is used by
  # the wells_with_aliquots_must_have_donor_id method to generate an error
  # message.
  #
  # @return [Hash] A hash mapping source plate barcodes to arrays of invalid
  #   well locations.
  def locations_with_missing_donor_id
    # source_wells_for_pooling contains filtered wells from source plates
    invalid_wells = source_wells_for_pooling.select { |well| missing_donor_id?(well) }
    invalid_wells_hash(invalid_wells)
  end

  # Checks if a well is missing a donor_id. If there is an aliquot, it checks
  # if the associated sample_metadata has a donor_id. If the donor_id is
  # missing, it returns true. Otherwise, it returns false.
  #
  # @param well [Well] The well to check.
  # @return [Boolean] True if the well is missing a donor_id, false otherwise.
  def missing_donor_id?(well)
    aliquot = well.aliquots&.first
    return false unless aliquot

    (aliquot.sample.sample_metadata.donor_id || '').to_s.strip.blank?
  end

  # Checks each source well for pooling for missing cell count. Returns a hash
  # with keys as the barcodes of source plates and values as arrays of well
  # locations with missing cell count. If a plate has no wells with missing
  # cell count, it is not included in the returned hash. This method is used by
  # the wells_with_aliquots_must_have_cell_count method to generate an error
  # message.
  #
  # @return [Hash] A hash mapping source plate barcodes to arrays of invalid
  #   well locations.
  def locations_with_missing_cell_count
    invalid_wells = source_wells_for_pooling.select { |well| missing_cell_count?(well) }
    invalid_wells_hash(invalid_wells)
  end

  # Checks if a well is missing a latest live cell count. If the cell count is
  # missing, it returns true. Otherwise, it returns false.
  #
  # @param well [Well] The well to check.
  # @return [Boolean] True if the well is missing a cell count, false otherwise.
  def missing_cell_count?(well)
    well.latest_live_cell_count.blank?
  end

  # Generates a hash mapping plate barcodes to invalid well locations. For each
  # invalid well, it finds the corresponding plate barcode and adds the well's
  # location to the list of invalid locations for that plate.
  #
  # @param invalid_wells [Array] the wells to be processed
  # @return [Hash] a hash mapping plate barcodes to arrays of invalid well locations
  def invalid_wells_hash(invalid_wells)
    invalid_wells.each_with_object({}) do |well, hash|
      plate_barcode = source_wells_to_plates[well].human_barcode # find the plate barcode
      hash[plate_barcode] ||= []
      hash[plate_barcode] << well.location
    end
  end

  # Formats a hash of invalid wells for display. For each plate barcode, it
  # concatenates the invalid well locations into a string, separated by commas.
  # It then joins these strings into a single string, separated by spaces.
  #
  # @param invalid_wells_hash [Hash] a hash mapping plate barcodes to arrays of
  #   invalid well locations
  # @return [String] a string representation of the invalid wells
  def formatted_invalid_wells_hash(invalid_wells_hash)
    invalid_wells_hash.map { |barcode, locations| "#{barcode}: #{locations.join(', ')}" }.join(' ')
  end

  # Validates that pools can be built. If any exceptions are raised during the
  # calculation, they are caught and added to the errors collection, which
  # makes the result of the save method false because of the valid? call. The
  # creation controller will then add the error messages to the flash.
  #
  # The advantages of this approach are:
  # - If the pools cannot be built, the create_labware! method will not be
  # called at all and the exceptions will be converted to error messages.
  # - If the pools can be built, the create_labware! method will use the cached
  # result to generate the transfers.
  #
  # @return [void]
  def validate_pools_can_be_built
    begin
      pools
    rescue StandardError => e
      errors.add(:pools, e.message)
    end
    nil
  end
end
