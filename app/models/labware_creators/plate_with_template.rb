# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  class PlateWithTemplate < Base
    include SupportParent::PlateOnly
  end
end
