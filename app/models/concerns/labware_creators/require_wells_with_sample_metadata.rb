# frozen_string_literal: true

# Can be included in plate creators which requires well aliquots to have sample metadata
module LabwareCreators::RequireWellsWithSampleMetadata
  extend ActiveSupport::Concern

  # Validation method that can be called to check that all wells, with aliquots,
  # have an associated sample metadata.
  def wells_with_aliquots_have_sample_metadata?
    invalid_well_locations = wells_with_missing_sample_metadata
    return if invalid_well_locations.empty?

    msg = 'wells missing sample metadata:'
    errors.add(:source_plate, "#{msg} #{invalid_well_locations.join(', ')}")
  end

  private

  def wells_with_missing_sample_metadata
    source_plate
      .wells
      .each_with_object([]) do |well, invalid_locations|
        next if well.aliquots.blank?

        invalid_locations << well.location if well.aliquots.first.sample.sample_metadata&.collected_by.nil?
      end
  end
end
