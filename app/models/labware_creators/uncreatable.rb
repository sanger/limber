# frozen_string_literal: true

module LabwareCreators
  # Purposes with the Uncreatable creator can't be created, so will not appear
  # in the 'Other plates' dropdown. This should be reserved for labware which
  # will fail to function correctly if created through Limber.
  # In practice this class behaves just like the base creator, but has been
  # sub-classed to better communicate its intent.
  # Doesn't create anything, but provide a useful error message.
  class Uncreatable < Base
    # This creator is invalid for all parents.
    self.page = 'uncreatable'

    # @note This actually duplicates the behaviour on the base class, so is not
    #       required for correct functionality. However I've decided to include
    #       it here for reasons of clarity.
    def self.creatable_from?(_parent)
      false
    end

    # Gather information for the view for user and developer debugging purposes

    # Returns the labware type of the parent labware purpose
    def parent_labware_type
      Settings.purposes.fetch(parent_purpose.uuid)&.fetch(:asset_type, 'unknown labware type')
    end

    # Returns the name of the parent purpose, or 'Unknown Purpose' if unavailable.
    def parent_purpose_name
      parent_purpose&.name || 'Unknown Purpose'
    end

    # Returns the name of the child purpose
    def child_purpose_name
      purpose_name
    end

    # Returns the labware type of the child purpose
    def child_labware_type
      purpose_config.asset_type
    end

    private

    def parent
      @parent ||= Sequencescape::Api::V2::Labware.find(uuid: parent_uuid).first
    end

    def parent_purpose
      @parent_purpose ||= parent.purpose
    end
  end
end
