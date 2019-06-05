# frozen_string_literal: true

module LabwareCreators
  # Basic quadrant stamp behaviour, applies no special request filters
  # See MultiStamp for further documentation
  #
  # Handles the generation of 384 well plates from 1-4 96 well plates.
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
  # The transfers layout 'quadrant' descibed above is implemented client side.
  #
  class QuadrantStampBase < MultiStamp
    self.transfers_layout = 'quadrant'
    self.target_rows = 16
    self.target_columns = 24
    self.source_plates = 4

    private

    def create_labware!
      super do |child|
        PlateMetadata.new(
          api: api,
          user: user_uuid,
          plate: child
        ).update!(stock_barcodes_by_quadrant)
        yield(child) if block_given?
      end
    end

    def source_plates_by_quadrant
      source_plates_uuids = Array.new(4)
      transfers.each do |transfer|
        target_well_location = transfer.dig(:new_target, :location)
        target_well_quadrant = WellHelpers.well_quadrant(target_well_location)
        if source_plates_uuids[target_well_quadrant].nil?
          source_plates_uuids[target_well_quadrant] = transfer[:source_plate]
        end
      end
      source_plates_uuids
    end

    def stock_barcodes_by_quadrant
      quadrants = {}
      source_plates_by_quadrant.each_with_index do |uuid, index|
        next if uuid.nil?

        source_plate = Sequencescape::Api::V2::Plate.find_by(uuid: uuid)
        stock_barcode = source_plate&.stock_plate&.barcode&.human
        quadrants["stock_barcode_q#{index}".to_sym] = stock_barcode unless stock_barcode.nil?
      end
      quadrants
    end
  end
end
