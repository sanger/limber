require_dependency 'labware_creators'

module LabwareCreators
  # A primer panel is a collection of primers
  # used to amplify specific regions of DNA
  # for the purposes of genotyping.
  # It is specified at submission, and should
  # be consistent across the entire plate
  class PlateWithAutoSubmission < StampedPlate
    include LabwareCreators::AutoSubmissionBehaviour
  end
end
