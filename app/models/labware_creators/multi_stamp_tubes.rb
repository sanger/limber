# frozen_string_literal: true

module LabwareCreators
  class MultiStampTubes < Base # rubocop:todo Style/Documentation
    include LabwareCreators::CustomPage
    include SupportParent::TubeOnly

    attr_accessor :transfers, :parents

    class_attribute :request_filter, :transfers_layout, :transfers_creator, :target_rows, :target_columns, :source_tubes

    self.page = 'multi_stamp_tubes'
    self.aliquot_partial = 'standard_aliquot'
    self.request_filter = 'null'
    self.transfers_layout = 'null'
    self.transfers_creator = 'multi-stamp-tubes'
    self.target_rows = 0
    self.target_columns = 0
    self.source_tubes = 0

    validates :transfers, presence: true

    private

    def create_labware!
      plate_creation = api.pooled_plate_creation.create!(
        parents: parent_uuids,
        child_purpose: purpose_uuid,
        user: user_uuid
      )

      @child = plate_creation.child

      transfer_material_from_parent!(@child.uuid)

      yield(@child) if block_given?
      true
    end

    # Returns a list of parent tube uuids extracted from the transfers
    def parent_uuids
      transfers.pluck(:source_tube).uniq
    end

    def transfer_material_from_parent!(child_uuid)
      child_plate = Sequencescape::Api::V2.plate_with_wells(child_uuid)
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes(child_plate)
      )
    end

    def transfer_request_attributes(child_plate)
      transfers.map do |transfer|
        request_hash(transfer, child_plate)
      end
    end

    def request_hash(transfer, child_plate)
      {
        'source_asset' => transfer[:source_asset],
        'target_asset' => child_plate.wells.detect do |child_well|
                            child_well.location == transfer.dig(:new_target, :location)
                          end&.uuid
      }
    end
  end
end
