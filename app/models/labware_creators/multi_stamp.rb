# frozen_string_literal: true

module LabwareCreators
  class MultiStamp < Base # rubocop:todo Style/Documentation
    include LabwareCreators::CustomPage
    include CreatableFrom::PlateOnly

    attr_accessor :transfers, :parents

    class_attribute :request_filter,
                    :transfers_layout,
                    :transfers_creator,
                    :target_rows,
                    :target_columns,
                    :source_plates,
                    :acceptable_purposes

    self.page = 'multi_stamp'
    self.aliquot_partial = 'standard_aliquot'
    self.request_filter = 'null'
    self.transfers_layout = 'null'
    self.transfers_creator = 'multi-stamp'
    self.target_rows = 0
    self.target_columns = 0
    self.source_plates = 0
    self.acceptable_purposes = []

    validates :transfers, presence: true

    private

    def create_labware!
      @child =
        Sequencescape::Api::V2::PooledPlateCreation.create!(
          child_purpose_uuid: purpose_uuid,
          parent_uuids: parent_uuids,
          user_uuid: user_uuid
        ).child

      transfer_material_from_parent!(@child.uuid)

      yield(@child) if block_given?
      true
    end

    # Returns a list of parent plate uuids extracted from the transfers
    def parent_uuids
      transfers.pluck(:source_plate).uniq
    end

    def transfer_material_from_parent!(child_uuid)
      child_plate = Sequencescape::Api::V2.plate_with_wells(child_uuid)
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes(child_plate),
        user_uuid: user_uuid
      )
    end

    def transfer_request_attributes(child_plate)
      transfers.map { |transfer| request_hash(transfer, child_plate) }
    end

    def request_hash(transfer, child_plate)
      {
        source_asset: transfer[:source_asset],
        target_asset:
          child_plate.wells.detect { |child_well| child_well.location == transfer.dig(:new_target, :location) }&.uuid,
        outer_request: transfer[:outer_request]
      }
    end
  end
end
