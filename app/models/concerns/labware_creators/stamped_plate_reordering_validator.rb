# frozen_string_literal: true

# This module contains validations for stamped plate reordering columns to rows.
module LabwareCreators::StampedPlateReorderingValidator
  extend ActiveSupport::Concern

  SOURCE_WELLS_MUST_FIT_CHILD_PLATE = "The number of source wells (%s) exceeds the child plate's size (%s)."

  included { validate :source_wells_must_fit_child_plate }

  # Validates that the number of parent wells does not exceed the child plate
  # size. It uses the labware_wells method to get the parent wells, which the
  # same method called by the well filter to get the input wells for filtering.
  #
  # @return [void]
  def source_wells_must_fit_child_plate
    # Read the child plate size from the purpose configuration. purpose_uuid is
    # the uuid of the child plate purpose.

    child_plate_size = Settings.purposes[purpose_uuid][:size] || 96
    return if labware_wells.size <= child_plate_size

    errors.add(:source_plate, format(SOURCE_WELLS_MUST_FIT_CHILD_PLATE, labware_wells.size, child_plate_size))
  end
end
