# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  class PlateWithTemplate < Base # rubocop:todo Style/Documentation
    include SupportParent::PlateOnly

    def transfer_material_from_parent!(child_uuid)
      transfer_template.create!(source: parent_uuid, destination: child_uuid, user: user_uuid)
    end
  end
end
