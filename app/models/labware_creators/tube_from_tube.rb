# frozen_string_literal: true

module LabwareCreators
  # For simple tube to tube transfers
  class TubeFromTube < Base
    extend SupportParent::TubeOnly

    self.default_transfer_template_name = 'Transfer between specific tubes'

    attr_reader :tube_transfer

    def create_labware!
      @child_tube = api.tube_from_tube_creation.create!(
        parent: parent_uuid,
        child_purpose: purpose_uuid,
        user: user_uuid
      ).child

      @tube_transfer = transfer_template.create!(
        user: user_uuid,
        source: parent_uuid,
        destination: @child_tube.uuid
      )
      true
    end

    # We pretend that we've added a new blank tube when we're actually
    # transfering to the tube on the original LibraryRequest
    def child
      @child_tube
    end
  end
end
