# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  class StampedPlate < Base
    include SupportParent::PlateOnly
    self.default_transfer_template_name = 'Custom pooling'

    def parent
      @parent ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
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
      parent.wells.reject { |w| w.empty? || w.failed? }.map do |well|
        request_hash(well, child_plate)
      end
    end

    def request_hash(source_well, child_plate)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect { |child_well| child_well.location == source_well.location }&.uuid,
        'outer_request' => filter_requests(source_well.active_requests).uuid
      }
    end

    def filter_requests(requests)
      requests.first
    end
  end
end
