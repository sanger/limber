# frozen_string_literal: true

module LabwareCreators
  # Creates a new tube per submission, and transfers all the wells matching that submission
  # into each tube.
  class PooledTubesBySubmission < Base
    extend SupportParent::TaggedPlateOnly
    attr_reader :tube_transfer

    self.default_transfer_template_uuid = Settings.transfer_templates['Transfer wells to specific tubes defined by submission']

    def create_labware!
      child_stock_tubes = api.specific_tube_creation.create!(
        user: user_uuid,
        parent: parent_uuid,
        child_purposes: [purpose_uuid] * pool_uuids.length
      ).children.map(&:uuid)

      transfer_requests = []

      pools.values.each_with_index do |pool, index|
        pool['wells'].each do |location|
          transfer_requests << {
            'source_asset' => well_locations[location],
            'target_asset' => child_stock_tubes[index]
          }
        end
      end

      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_requests
      )
      true
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

    private

    delegate :pools, to: :parent

    #
    # Maps well locations to the corresponding uuid
    #
    # @return [Hash] Hash with well locations (eg. 'A1') as keys, and uuids as values
    #
    def well_locations
      @well_locations ||= parent.wells.each_with_object({}) do |w,hash|
        hash[w.location] = w.uuid
      end
    end
  end
end
