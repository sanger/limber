# frozen_string_literal: true

module LabwareCreators
  #
  # Handles the generation of 384 well plates from 1-4 96 well plates.
  # Most the layout logic happens client side, and it should be possible
  # to adapt this creator to support a range of layouts by pretty much just
  # switching out the page/javascript
  #
  # Briefly, 96 well plates get stamped onto 384 plates in an interpolated pattern
  # eg.
  # +--+--+--+--+--+--+--~
  # |P1|P3|P1|P3|P1|P3|P1
  # |A1|A1|A2|A2|A3|A3|A4
  # +--+--+--+--+--+--+--~
  # |P2|P4|P2|P4|P2|P4|P1
  # |A1|A1|A2|A2|A3|A3|A4
  # +--+--+--+--+--+--+--~
  # |P1|P3|P1|P3|P1|P3|P1
  # |B1|B1|B2|B2|B3|B3|B4
  # +--+--+--+--+--+--+--~
  # |P2|P4|P2|P4|P2|P4|P1
  # |B1|B1|B2|B2|B3|B3|B4
  #
  class QuadrantStamp < Base
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly

    attr_accessor :transfers, :parents

    self.page = 'quadrant_stamp'
    self.aliquot_partial = 'standard_aliquot'
    self.attributes += [{ transfers: [] }]

    private

    def create_labware!
      plate_creation = api.pooled_plate_creation.create!(
        parents:        parent_uuids,
        child_purpose:  purpose_uuid,
        user:           user_uuid
      )

      @child = plate_creation.child

      transfer_material_from_parent!(@child.uuid)

      yield(@child) if block_given?
      true
    end

    # Returns a list of parent plate uuids extracted from the transfers
    def parent_uuids
      transfers.map { |transfer| transfer[:source_plate] }.uniq
    end

    def transfer_material_from_parent!(child_uuid)
      child_plate = Sequencescape::Api::V2::Plate.find_by({ uuid: child_uuid }, includes: 'wells')
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
        'target_asset' => child_plate.wells.detect { |child_well| child_well.location == transfer.dig(:new_target, :location) }&.uuid,
        'outer_request' => transfer[:outer_request]
      }
    end
  end
end
