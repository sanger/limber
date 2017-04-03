# frozen_string_literal: true

module Forms
  # Pools an entire plate into a single tube. Useful for MiSeqQC
  class PooledTubesForm < CreationForm
    attr_reader :tube_transfer

    def create_labware!
      # Create a single tube
      child_tube = api.specific_tube_creation.create!(
        user: user_uuid,
        parent: labware.uuid,
        child_purposes: [purpose_uuid]
      ).children.first

      # Transfer EVERYTHING into it
      @tube_transfer = api.transfer_template.find(
        Settings.transfer_templates['Whole plate to tube']
      ).create!(
        user: user_uuid,
        source: labware.uuid,
        destination: child_tube.uuid
      )
      true
    rescue => e
      false
    end

    def child
      tube_transfer.try(:destination) || :contents_not_transfered
    end
  end
end
