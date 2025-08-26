# frozen_string_literal: true

module LabwareCreators
  # For simple tube to tube transfers
  class TubeFromTube < Base
    include CreatableFrom::TubeOnly

    self.default_transfer_template_name = 'Transfer between specific tubes'

    attr_reader :tube_transfer

    def create_labware!
      @child_tube =
        Sequencescape::Api::V2::TubeFromTubeCreation.create!(
          child_purpose_uuid: purpose_uuid,
          parent_uuid: parent_uuid,
          user_uuid: user_uuid
        ).child

      @tube_transfer = transfer!(source_uuid: parent_uuid, destination_uuid: @child_tube.uuid)

      true
    end

    # We pretend that we've added a new blank tube when we're actually
    # transfering to the tube on the original LibraryRequest
    def redirection_target
      @child_tube
    end
  end
end
