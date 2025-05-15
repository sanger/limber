# frozen_string_literal: true

require_dependency './lib/repeated_state_change_error'

module LabwareCreators
  # Duplicate of TaggedPlate Creator to allow configuration to be built independently
  # of behaviour.
  class CustomTaggedPlate < Base
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly
    include LabwareCreators::TaggedPlateBehaviour

    attr_reader :child, :tag_plate
    attr_accessor :tag_layout
    self.page = 'custom_tagged_plate'
    self.attributes += [
      {
        tag_plate: %i[asset_uuid template_uuid state],
        tag_layout: [
          :user_uuid,
          :plate_uuid,
          :tag_group_uuid,
          :tag2_group_uuid,
          :direction,
          :walking_by,
          :initial_tag,
          :tags_per_well,
          { substitutions: {} }
        ]
      }
    ]
    self.default_transfer_template_name = 'Custom pooling'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate, presence: true

    delegate :size, :number_of_columns, :number_of_rows, to: :labware

    def tag_plate=(params)
      @tag_plate = OpenStruct.new(params) # rubocop:todo Style/OpenStructUse
    end

    def initialize(*args, &)
      super
      parent.assign_pools_to_wells
    end

    def create_plate! # rubocop:todo Metrics/AbcSize
      @child =
        Sequencescape::Api::V2::PooledPlateCreation.create!(
          child_purpose_uuid: purpose_uuid,
          parent_uuids: [parent_uuid, tag_plate.asset_uuid].compact_blank,
          user_uuid: user_uuid
        ).child

      transfer_material_from_parent!(@child.uuid)

      yield(@child.uuid) if block_given?

      return true if tag_plate.asset_uuid.blank? || tag_plate.state == 'exhausted'

      begin
        flag_tag_plate_as_exhausted
      rescue RepeatedStateChangeError => e
        # Plate is already exhausted, the user is probably processing two plates
        # at the same time
        Rails.logger.warn(e.message)
      end
      true
    end

    def pool_index(_pool_index)
      nil
    end

    #
    # The tags per well number.
    # In most cases this will be the default 1 unless overriden in the purposes yml
    # e.g. for Chromium plates in bespoke it is 4
    #
    # @return [<Number] The number of tags per well.
    #
    def tags_per_well
      purpose_config.fetch(:tags_per_well, 1)
    end

    #
    # The adapter type name filter for limiting the tag group list drop downs on the custom tagging
    # screen. In most cases this will not be present in the purposes yml and is not required.
    # e.g. to just show tag groups with Chromium adapter types it is 'Chromium'
    #
    # @return [<String] The name of the adapter type.
    #
    def tag_group_adapter_type_name_filter
      purpose_config.fetch(:tag_group_adapter_type_name_filter, nil)
    end

    private

    def tag_layout_attributes
      tag_layout.compact_blank
    end

    def create_labware!
      create_plate! do |plate_uuid|
        Sequencescape::Api::V2::TagLayout.create!(tag_layout_attributes.merge(plate_uuid:, user_uuid:))
      end
    end

    #
    # Transfers material from the parent plate to the specified child plate.
    # This method generates transfer requests and ensures that they are unique
    # based on the combination of `source_asset` and `target_asset`.
    # It then creates a transfer request collection via the Sequencescape API.
    #
    # @param [String] child_uuid The UUID of the child plate to which material will be transferred.
    #
    # @raise [RuntimeError] If the destination plate (child plate) cannot be found for the given `child_uuid`.
    #   Error message: "Destination plate not found for UUID: #{child_uuid}".
    #
    # @return [Boolean] Returns `true` if the transfer requests are successfully created.
    #
    def transfer_material_from_parent!(child_uuid)
      dest_plate = Sequencescape::Api::V2::Plate.find_by(uuid: child_uuid)
      raise "Destination plate not found for UUID: #{child_uuid}" unless dest_plate

      # TransferRequestCollection is a collection of transfer requests
      # created in the Sequencescape API.
      #
      # The `transfer_requests_attributes` parameter is an array of hashes,
      # where each hash represents a transfer request with the following keys:
      #   - `:source_asset` [String]: The UUID of the source asset (well) from the parent plate.
      #   - `:target_asset` [String]: The UUID of the target asset (well) in the child plate.
      #   - `:outer_request` [String]: The UUID of the outer request associated with the transfer.
      #
      # The `transfer_requests_attributes` parameter is required when transferring
      # specific request types from the parent plate to the destination plate. This is
      # particularly useful in cases where multiple request types exist in the parent plate,
      # and only a specific type needs to be transferred to the child plate.
      #
      # This is utilized within the `transfer_material_from_parent!` method to ensure
      # that the correct transfer requests are created and grouped for processing.
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: build_transfer_requests_attributes(dest_plate),
        user_uuid: user_uuid
      )
      true
    end

    # Generates transfer requests for the specified child plate.
    # This method maps each well in the parent plate to its corresponding request and target asset in the child plate.
    #
    # @param [Sequencescape::Api::V2::Plate] child_plate The destination plate object for the transfers.
    #
    # @return [Array<Hash>] An array of hashes, where each hash represents a transfer request with the following keys:
    #   - `:source_asset` [String]: The UUID of the source asset (well) from the parent plate.
    #   - `:outer_request` [String]: The UUID of the outer request associated with the transfer.
    #   - `:target_asset` [String, nil]: The UUID of the target asset (well) in the child plate, or `nil` if not found.
    #
    # @example Example Output
    #   [
    #     {
    #       source_asset: "source-uuid-1",
    #       outer_request: "request-uuid-1",
    #       target_asset: "target-uuid-1"
    #     },
    #     {
    #       source_asset: "source-uuid-2",
    #       outer_request: "request-uuid-2",
    #       target_asset: "target-uuid-2"
    #     }
    #   ]
    # This assumes a 'straight stamp' from source to destination plate,
    # meaning well A1 goes to well A1, A2 to A2, etc.
    #

    def build_transfer_requests_attributes(child_plate)
      parent.wells.filter_map do |well|
        # We've got to assume there's only one relevant request to be processed here,
        # because we wouldn't know what to do with more than one.
        next unless (request = well.active_requests.first)

        target_asset = child_plate.wells.find { |child_well| child_well.location == well.location }&.uuid
        { source_asset: well.uuid, outer_request: request.uuid, target_asset: target_asset }
      end
    end
  end
end
