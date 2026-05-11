# frozen_string_literal: true

# A variant of TenStamp that transfers all wells containing aliquots,
# regardless of whether they have active requests.
module LabwareCreators
  class TenStampAllWells < TenStamp # rubocop:todo Style/Documentation
    def transfer_all_wells?
      true
    end
  end
end
