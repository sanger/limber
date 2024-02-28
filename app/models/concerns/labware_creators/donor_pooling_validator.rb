# frozen_string_literal: true

# This module contains validations for donor pooling.
module LabwareCreators::DonorPoolingValidator
  extend ActiveSupport::Concern

  include ActiveModel::Validations

  included do
    validate :source_barcodes_must_be_entered
    validate :source_barcodes_must_be_different
    validate :source_plates_must_exist
    validate :number_of_pools_must_not_exceed_configured
  end

  SOURCE_BARCODES_MUST_BE_ENTERED = 'should be entered, Please scan in all the required source plate barcodes.'

  SOURCE_BARCODES_MUST_BE_DIFFERENT = 'should not have the same barcode, please check you scanned all the plates.'

  SOURCE_PLATES_MUST_EXIST = 'not found, please check you scanned the correct source plates.'

  NUMBER_OF_POOLS_MUST_NOT_EXCEED_CONFIGURED =
    'The number of pools calculated (%s) is higher than the number of pools ' \
      '(%s) configured. Please check you have scanned the correct set of ' \
      'source plates.'

  def source_barcodes_must_be_entered
    return if minimal_barcodes.size >= 1

    errors.add(:source_barcodes, SOURCE_BARCODES_MUST_BE_ENTERED)
  end

  def source_barcodes_must_be_different
    return if minimal_barcodes.size == minimal_barcodes.uniq.size

    errors.add(:source_barcodes, SOURCE_BARCODES_MUST_BE_DIFFERENT)
  end

  def source_plates_must_exist
    return if source_plates.size == minimal_barcodes.size

    errors.add(:source_plates, SOURCE_PLATES_MUST_EXIST)
  end

  def number_of_pools_must_not_exceed_configured
    return if pools.size <= number_of_pools

    errors.add(
      :source_plates,
      format(NUMBER_OF_POOLS_MUST_NOT_EXCEED_CONFIGURED, pools.size, number_of_pools)
    )
  end
end
