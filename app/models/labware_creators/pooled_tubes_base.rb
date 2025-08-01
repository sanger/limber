# frozen_string_literal: true

module LabwareCreators
  # Creates a new tube per pool, and transfers from wells into that pool
  # Leaves the pooling logic - allocation of wells to pools - to subclasses to implement
  # TODO: transfer_request_attributes currently assumes the pool identifier is
  # the submission uuid - this should be changed
  class PooledTubesBase < Base
    include CreatableFrom::TaggedPlateOnly

    attr_reader :tube_transfer, :child_stock_tubes
    attr_writer :metadata_stock_barcode

    def create_labware!
      @child_stock_tubes = create_child_stock_tubes
      perform_transfers
      true
    end

    def create_child_stock_tubes
      Sequencescape::Api::V2::SpecificTubeCreation
        .create!(
          child_purpose_uuids: [purpose_uuid] * pool_uuids.length,
          parent_uuids: [parent_uuid],
          tube_attributes: tube_attributes,
          user_uuid: user_uuid
        )
        .children
        .index_by(&:name)
    end

    def perform_transfers
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes,
        user_uuid: user_uuid
      )
    end

    def transfer_request_attributes
      pools.each_with_object([]) do |(pool_identifier, pool), transfer_requests|
        # this currently assumes that pool_identifier will be the submission_uuid
        # (it would have always been, historically)
        pool.each do |location|
          transfer_requests << request_hash(
            well_locations.fetch(location).uuid,
            child_stock_tubes.fetch(name_for(pool)).uuid,
            pool_identifier
          )
        end
      end
    end

    def request_hash(source, target, submission)
      { source_asset: source, target_asset: target, submission: submission }
    end

    def pool_uuids
      pools.keys
    end

    # We may create multiple tubes, so cant redirect onto any particular
    # one. Redirecting back to the parent is a little grim, so we'll need
    # to come up with a better solution.
    # 1) Redirect to the transfer/creation and list the tubes that way
    # 2) Once tube racks are implemented, we can redirect there.
    def redirection_target
      parent
    end

    def anchor
      'relatives_tab'
    end

    private

    def tube_attributes
      pools.values.map { |pool_details| { name: name_for(pool_details) } }
    end

    def name_for(pool_details)
      first, last = WellHelpers.first_and_last_in_columns(pool_details)
      "#{stock_plate_barcode} #{first}:#{last}"
    end

    def legacy_barcode
      ("#{parent.stock_plate.barcode.prefix}#{parent.stock_plate.barcode.number}" if parent.stock_plate) || nil
    end

    def stock_plate_barcode
      metadata_stock_barcode || legacy_barcode
    end

    def metadata_stock_barcode
      @metadata_stock_barcode ||= parent_metadata.fetch('stock_barcode', nil)
    end

    def parent_metadata
      LabwareMetadata.new(labware: parent).metadata || {}
    end

    # Maps well locations to the corresponding uuid
    #
    # @return [Hash] Hash with well locations (eg. 'A1') as keys, and uuids as values
    def well_locations
      @well_locations ||= parent.wells.index_by(&:location)
    end

    # pools should return a hash of pools with the following minimal information
    # { 'unique-pool-identifier' => <Array of well locations> }
    #
    # @return [<type>] <description>
    #
    def pools
      raise '#pools must be implemented on subclasses'
    end
  end
end
