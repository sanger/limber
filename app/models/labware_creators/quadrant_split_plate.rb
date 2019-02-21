# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  # Splits a 384 well plate into four separate 96 well
  # plates.
  class QuadrantSplitPlate < StampedPlate
    #
    # We've created multiple plates, so we redirect to the parent.
    #
    # @return [Sequencescape::Api::V2::Plate] The parent plate
    def redirection_target
      parent
    end

    private

    def create_labware!
      creations = Array.new(4) { create_plate_from_parent! }
      children = creations.map(&:child)
      transfer_material_from_parent!(children.map(&:uuid))
      children.each do |child|
        yield(child) if block_given?
      end
      true
    end

    def transfer_material_from_parent!(children_uuid)
      children = Sequencescape::Api::V2::Plate.find_all({ uuid: children_uuid }, includes: ['wells'])

      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes(children)
      )
    end

    def transfer_request_attributes(child_plates)
      well_filter.filtered.map do |well, additional_parameters|
        request_hash(well, child_plates, additional_parameters)
      end
    end

    def request_hash(source_well, child_plates, additional_parameters)
      col, row = source_well.coordinate
      child_plate_index = 2 * (col % 2) + (row % 2)
      child_well_name = WellHelpers.well_name(row / 2, col / 2)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plates[child_plate_index].wells.detect { |child_well| child_well.location == child_well_name }&.uuid
      }.merge(additional_parameters)
    end
  end
end
