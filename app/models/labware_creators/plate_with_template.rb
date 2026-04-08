# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  class PlateWithTemplate < Base # rubocop:todo Style/Documentation
    include CreatableFrom::PlateOnly

    def transfer_material_from_parent!(child_uuid)
      transfer!(source_uuid: parent_uuid, destination_uuid: child_uuid)
    end
  end
end
