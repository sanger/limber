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
      transfer_template.create!(
        source: parent_uuid,
        destination: child_uuid,
        user: user_uuid,
        transfers: transfer_hash
      )
    end

    def transfer_hash
      WellHelpers.stamp_hash(parent.size)
    end
  end
end
