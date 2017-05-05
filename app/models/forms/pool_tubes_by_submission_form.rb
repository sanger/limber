# frozen_string_literal: true

module Forms
  # Pools an entire plate into a single tube. Useful for MiSeqQC
  class PoolTubesBySubmissionForm < CreationForm
    attr_reader :tube_transfer

    self.default_transfer_template_uuid = Settings.transfer_templates['Transfer wells to specific tubes defined by submission']

    def create_labware!
      child_stock_tubes = api.specific_tube_creation.create!(
        user: user_uuid,
        parent: parent_uuid,
        child_purposes: [purpose_uuid] * pool_uuids.length
      ).children

      api.transfer_template.find(default_transfer_template_uuid).create!(
        user: user_uuid,
        source: parent_uuid,
        targets: Hash[pool_uuids.zip(child_stock_tubes.map(&:uuid))]
      )
      true
    rescue => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
      false
    end

    def parent
      @parent ||= api.plate.find(parent_uuid)
    end

    def pool_uuids
      parent.pools.keys
    end

    # We may create multiple tubes, so cant redirect onto any particular
    # one. Redirecting back to the parent is a little grim, so we'll need
    # to come up with a better solution.
    # 1) Redirect to the transfer/creation and list the tubes that way
    # 2) Once tube racks are implemented, we can redirect there.
    def child
      parent
    end
  end
end
