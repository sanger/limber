# frozen_string_literal: true

# Can be included in plate creators which requires well aliquots to have collected_by sample metadata
module LabwareCreators::RequireWellsWithCollectedBy
  extend ActiveSupport::Concern

  # Validation method that can be called to check that all wells, with aliquots,
  # have an associated sample metadata, with collected_by.
  def wells_with_aliquots_have_collected_by?
    invalid_well_locations = wells_with_missing_collected_by
    return if invalid_well_locations.empty?

    msg = 'wells missing collected_by sample metadata:'
    errors.add(:source_plate, "#{msg} #{invalid_well_locations.join(', ')}")
  end

  private

  def wells_with_missing_collected_by
    source_plate
      .wells
      .each_with_object([]) do |well, invalid_locations|
        next if well.aliquots.blank?

        invalid_locations << well.location if well.aliquots.first.sample.sample_metadata&.collected_by.nil?
      end
  end
end
