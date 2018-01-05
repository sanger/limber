# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  class PlateWithTemplate < Base
    extend SupportParent::PlateOnly
  end
end
