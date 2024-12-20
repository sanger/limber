# frozen_string_literal: true

module LabwareCreators
  # Adds well filtering to the TaggedPlate labware creator.
  class WellFilteredTaggedPlateCreator < TaggedPlate
    include LabwareCreators::WellFilterBehaviour
    self.page = 'well_filtered_tagged_plate'
    self.should_populate_wells_with_pool = false # parent is a V2 plate
  end
end
