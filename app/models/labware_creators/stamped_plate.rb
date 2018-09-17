# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  class StampedPlate < Base
    include SupportParent::PlateOnly
    self.default_transfer_template_name = 'Custom pooling'
    self.attributes += [{ filter: {} }]

    def parent
      @parent ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
    end

    def filter=(filter_parameters)
      @filter = WellFilter.new(filter_parameters)
    end

    def filter
      @filter ||= WellFilter.new({})
    end

    private

    def transfer_material_from_parent!(child_uuid)
      child_plate = Sequencescape::Api::V2::Plate.find_by(uuid: child_uuid)
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes(child_plate)
      )
    end

    def transfer_request_attributes(child_plate)
      filter.filtered(parent.wells).map do |well, request|
        request_hash(well, child_plate, request)
      end
    end

    def request_hash(source_well, child_plate, request)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect { |child_well| child_well.location == source_well.location }&.uuid,
        'outer_request' => request.uuid
      }
    end
  end
end
