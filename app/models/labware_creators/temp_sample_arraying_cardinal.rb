# frozen_string_literal: true

# A temporary creator for sample arraying step in Cardinal pipeline, until the proper one is made
module LabwareCreators
  class TempSampleArrayingCardinal < StampedPlate
    include SupportParent::TubeOnly # Temp hack: this is used in 'compatible_purposes' in Presenters::CreationBehaviour - Multistamp creator will need this.
  end
end
