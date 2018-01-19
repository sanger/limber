# frozen_string_literal: true

module LabwareCreators
  # The multiplexed library tubes are created up front when the submission is created in Sequencescape
  # This allows for additional sequencing work to be requested while libraries are still being made.
  # JG: We should check if there are other aspects of this that are depended on
  # This form is used to transfer directly from a plate into the final tubes.
  # The transfer template finds the mx tube corresponding to each well, and transfers into it. As a result,
  # pooling may happen at this stage.
  # The tubes are also passed automatically. This behaviour is a time-saving (for the users) measure based on limitations
  # of the existing pipeline, and may be removed in future. Essentially, as used currently, the tubes are ACTUALLY part
  # of the previous plate, so are already filled by this stage.
  class FinalTubeFromPlate < Base
    include SupportParent::PlateReadyForPoolingOnly

    attr_reader :tube_transfer

    self.default_transfer_template_name = 'Transfer wells to MX library tubes by submission'

    def create_labware!
      transfer_into_existing_tubes!
      pass_tubes!
    end

    # We may create multiple tubes, so cant redirect onto any particular
    # one. Redirecting back to the parent is a little grim, so we'll need
    # to come up with a better solution.
    # 1) Redirect to the transfer/creation and list the tubes that way
    # 2) Once tube racks are implemented, we can redirect there.
    def child
      parent
    end

    private

    def transfer_into_existing_tubes!
      @transfer ||= transfer_template.create!(
        user: user_uuid,
        source: parent_uuid
      )
    end

    def pass_tubes!
      raise StandardError, 'Tubes cannot be passed before transfer' if @transfer.nil?
      tubes_from_transfer.each do |tube_uuid|
        api.state_change.create!(
          user: user_uuid,
          target: tube_uuid,
          target_state: 'passed'
        )
      end
    end

    def tubes_from_transfer
      @transfer.transfers.values.each_with_object(Set.new) do |tube_details, tube_uuids|
        tube_uuids << tube_details.fetch('uuid')
      end
    end

    def targets_from_transfers
      raise StandardError
    end
  end
end
