# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  class StampedPlate < Base
    extend SupportParent::PlateOnly
    self.default_transfer_template_uuid = Settings.transfer_templates['Custom pooling']

    private

    def transfer_material_from_parent!
      api.transfer_template.find(transfer_template_uuid).create!(
        source: parent_uuid,
        destination: @plate_creation.child.uuid,
        user: user_uuid,
        transfers: transfer_hash
      )
    end

    def transfer_hash
      WellHelpers.column_order(labware.size).each_with_object({}) { |well,hash| hash[well] = well }
    end
  end
end
