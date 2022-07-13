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

    def anchor
      'children_tab'
    end

    private

    def create_labware!
      creations = Array.new(4) { create_plate_from_parent! }
      children = creations.map(&:child)
      transfer_material_from_parent!(children.map(&:uuid))
      children.each { |child| yield(child) if block_given? }
      true
    end

    def transfer_material_from_parent!(children_uuid)
      children = Sequencescape::Api::V2::Plate.find_all({ uuid: children_uuid }, includes: ['wells']).to_a

      api.transfer_request_collection.create!(user: user_uuid, transfer_requests: transfer_request_attributes(children))
    end

    def transfer_request_attributes(child_plates)
      add_stock_barcode_metadata(child_plates)
      well_filter.filtered.map { |well, additional_parameters| request_hash(well, child_plates, additional_parameters) }
    end

    def add_stock_barcode_metadata(plates) # rubocop:todo Metrics/AbcSize
      merger_plate = parent.ancestors.where(purpose_name: SearchHelper.merger_plate_names).first
      metadata = LabwareMetadata.new(api: api, barcode: merger_plate.barcode.machine).metadata
      plates.each_with_index do |plate, index|
        stock_barcode = stock_barcode_from_quadrant(index, metadata) || "* #{plate.barcode.human}"
        LabwareMetadata
          .new(api: api, user: user_uuid, barcode: plate.barcode.machine)
          .update!(stock_barcode: stock_barcode)
      end
    end

    def stock_barcode_from_quadrant(index, metadata)
      metadata_hash = metadata || {}
      metadata_hash.fetch("stock_barcode_q#{index}", nil)
    end

    def request_hash(source_well, child_plates, additional_parameters)
      col, row = source_well.coordinate
      child_plate_index = source_well.quadrant_index
      child_well_name = WellHelpers.well_name(row / 2, col / 2)
      {
        'source_asset' => source_well.uuid,
        'target_asset' =>
          child_plates[child_plate_index].wells.detect { |child_well| child_well.location == child_well_name }&.uuid
      }.merge(additional_parameters)
    end
  end
end
