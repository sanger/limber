# frozen_string_literal: true

module LabwareCreators
  # Blends two parent tubes into a single child tube.
  #
  class BlendedTube < Base
    include LabwareCreators::CustomPage
    include SupportParent::TubeOnly

    attr_accessor :transfers

    class_attribute :transfers_creator

    self.page = 'blended_tube'
    self.transfers_creator = 'blended-tube'

    validates :transfers, presence: true
    validate :parents_suitable

    # Fetch the ancestor plate purpose type from purpose configuration
    def ancestor_labware_purpose_name
      purpose_config.dig(:creator_class, :args, :ancestor_labware_purpose_name)
    end

    def acceptable_parent_tube_purposes
      purpose_config.dig(:creator_class, :args, :acceptable_parent_tube_purposes).to_a
    end

    def single_ancestor_parent_tube_purpose
      purpose_config.dig(:creator_class, :args, :single_ancestor_parent_tube_purpose)
    end

    def redirection_target
      @child_tube
    end

    private

    def create_labware!
      @child_tube = create_child_tube
      perform_transfers
      true
    end

    def tube_attributes
      # TODO: ensure pairing component returns them in the same order by purpose
      [{ name: parents.map(&:human_barcode).join(':') }]
    end

    def create_child_tube
      Sequencescape::Api::V2::SpecificTubeCreation
        .create!(
          child_purpose_uuids: [purpose_uuid],
          parent_uuids: parents.map(&:uuid),
          tube_attributes: tube_attributes,
          user_uuid: user_uuid
        )
        .children
        .first
    end

    def perform_transfers
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes,
        user_uuid: user_uuid
      )
    end

    def parent_uuids
      transfers.pluck(:source_tube_uuid).uniq
    end

    def parents
      Sequencescape::Api::V2::Tube.find_all(uuid: parent_uuids, includes: 'receptacle,aliquots')
    end

    def transfer_request_attributes
      transfers.map { |transfer| request_hash(transfer) }
    end

    def request_hash(transfer)
      parent_tube = Sequencescape::Api::V2::Tube.find_by(uuid: transfer[:source_tube_uuid])

      { source_asset: parent_tube.uuid, target_asset: @child_tube.uuid }
    end

    def parents_suitable
      # TODO: validate parents - what we need to do here depends on what the pairing component does
      # internally.
      # The 2 parent tubes must have the expected purposes.
      # The 2 parent tubes must have different purposes.
      # The 2 parent tubes must have different barcodes.
      # The 2 parent tubes must have the same ancestor parent plate.
      # The 2 parent tubes must have a matching set of samples fron the same ancestor wells.
      # The 2 parent tubes must contain libraries that are compatible for blending. They will have the same tags.
      true
    end
  end
end
