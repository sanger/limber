# frozen_string_literal: true

module LabwareCreators
  # Multiple parent plates are transferred onto a single child plate
  # During this process wells are pooled according to the pre-capture
  # pools specified at submission.
  class MultiPlatePool < Base
    include CreatableFrom::TaggedPlateOnly
    include LabwareCreators::CustomPage

    attr_accessor :transfers

    self.page = 'multi_plate_pool'
    self.aliquot_partial = 'custom_pooled_aliquot'
    self.attributes += [{ transfers: {} }]

    private

    def create_labware!
      return false unless can_create_labware?

      @child =
        Sequencescape::Api::V2::PooledPlateCreation.create!(
          child_purpose_uuid: purpose_uuid,
          parent_uuids: transfers.keys,
          user_uuid: user_uuid
        ).child

      Sequencescape::Api::V2::BulkTransfer.create!(user_uuid:, well_transfers:)

      yield(@child) if block_given?
      true
    end

    # Checks whether labware can be created based on active requests
    # on parent plates if configured. For each parent plate, if it has any
    # active requests not in the allowed list, an error is added to the
    # creator's errors.
    # @return [Boolean] true if labware can be created, false otherwise
    def can_create_labware?
      return true if allowed_active_requests.blank? # No restrictions.

      transfers.each_key do |parent_uuid|
        parent = Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
        parent.active_requests.map(&:request_type).uniq.each do |request_type|
          add_request_error(request_type, parent) unless allowed_active_requests.include?(request_type.key)
        end
      end
      errors.none?
    end

    # Adds an error to the creator's errors indicating that the given
    # request needs closing before creating the child labware.
    # @param request [Sequencescape::Api::V2::RequestType] the active request type
    # @param parent [Sequencescape::Api::V2::Plate] the parent plate
    def add_request_error(request_type, parent)
      errors.add(:base,
                 I18n.t('errors.messages.request_needs_closing',
                        request_type_name: request_type.name,
                        parent_barcode: parent.human_barcode,
                        purpose_name: purpose_name))
    end

    # Returns an array of allowed active request keys on the parents to create
    # the child labware from the purpose config, or an empty array if not
    # configured. The result is cached after the first call.
    # @note This method handles two possible formats and normalizes them:
    #
    #   creator_class: LabwareCreators::MultiPlatePool
    #
    #   creator_class:
    #     name: LabwareCreators::MultiPlatePool
    #     args:
    #       allowed_active_requests:
    #         - limber_bge_isc
    #
    # @return [Array<String>] Array of allowed active request type keys
    def allowed_active_requests
      @allowed_active_requests ||= begin
        creator = purpose_config[:creator_class]
        creator_hash = creator.is_a?(Hash) ? creator : {}
        # Read the array, and reject blank values.
        creator_hash.dig(:args, :allowed_active_requests).to_a.compact_blank
      end
    end

    # Returns an array of a hash describing individual transfers
    # based on the input transfers. Example below:
    # {
    #   'source_uuid' => 'source-plate-uuid',
    #   'source_location' => 'A1',
    #   'destination_uuid' => child-plate-uuid,
    #   'destination_location' => 'A1'
    # }
    #
    # @return [Array<Hash>] Array of hashes describing each transfer
    #
    def well_transfers
      transfers = []
      each_well do |source_uuid, source_well, destination_uuid, destination_well|
        transfers << {
          'source_uuid' => source_uuid,
          'source_location' => source_well,
          'destination_uuid' => destination_uuid,
          'destination_location' => destination_well
        }
      end
      transfers
    end

    def each_well
      transfers.each do |source_uuid, well_well_transfers|
        well_well_transfers.each do |source_well, destination_well|
          yield(source_uuid, source_well, @child.uuid, destination_well)
        end
      end
    end
  end
end
