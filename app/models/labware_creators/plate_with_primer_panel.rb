# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  # A primer panel is a collection of primers
  # used to amplify specific regions of DNA
  # for the purposes of genotyping.
  # It is specified at submission, and should
  # be consistent across the entire plate
  class PlateWithPrimerPanel < StampedPlate
    include LabwareCreators::CustomPage
    include HasPrimerPanel

    self.page = 'plate_with_primer_panel'
  end
end
