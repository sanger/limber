# frozen_string_literal: true

module LabwareCreators
  # Pools an entire plate into a single tube. Useful for MiSeqQC
  class PooledTubesFromWholePlates < Base
    extend SupportParent::TaggedPlateOnly
    attr_reader :tube_transfer

    self.page = 'pooled_tubes_from_whole_plates'

    def create_labware!
      # Create a single tube
      child_tube = api.specific_tube_creation.create!(
        user: user_uuid,
        parent: parent_uuid,
        child_purposes: [purpose_uuid],
        tube_attributes: [{ name: 'DN1+' }]
      ).children.first

      # Transfer EVERYTHING into it
      @tube_transfer = transfer_template.create!(
        user: user_uuid,
        source: parent_uuid,
        destination: child_tube.uuid
      )
      true
    rescue
      false
    end

    def child
      tube_transfer.try(:destination) || :contents_not_transfered
    end

    private

    def transfer_template
      api.transfer_template.find(
        Settings.transfer_templates['Whole plate to tube']
      )
    end
  end
end
