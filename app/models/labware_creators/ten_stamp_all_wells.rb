# frozen_string_literal: true

module LabwareCreators
  # A variant of TenStamp that transfers all wells containing aliquots,
  # regardless of whether they have active requests.
  # Developed for scRNA aggregation, where the XP and Input plates will not have an active submission
  # at the time of transfer. Instead the submission will be made on the child Cherrypick plate.
  class TenStampAllWells < TenStamp
    # Flag to indicate that all wells with aliquots should be transferred, regardless of active requests.
    # Defaulted to false in MultiStamp (super class of TenStamp), but overriden to true here.
    # Passed through to the javascript for multi-stamping where it determines the behavior.
    def transfer_all_wells?
      true
    end
  end
end
