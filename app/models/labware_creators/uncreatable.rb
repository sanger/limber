# frozen_string_literal: true

module LabwareCreators
  # Purposes with the Uncreatable creator can't be created, so will not appear
  # in the 'Other plates' dropdown. This should be reserved for labware which
  # will fail to function correctly if created through Limber.
  # In practice this class behaves just like the base creator, but has been
  # sub-classed to better communicate its intent.
  class Uncreatable < Base
    # This creator is invalid for all parents.
    # @note This actually duplicates the behaviour on the base class, so is not
    #       required for correct functionality. However I've decided to include
    #       it here for reasons of clarity.
    def self.creatable_from?(_parent)
      false
    end
  end
end
