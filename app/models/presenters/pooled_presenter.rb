# frozen_string_literal: true

module Presenters
  class PooledPresenter < PlatePresenter
    include Presenters::Statemachine
    def plate
      labware
    end

    def walk_source
      PlateWalking::Walker.new(plate_to_walk, plate_to_walk.wells)
    end

    def walk_destination
      PlateWalking::Walker.new(labware, labware.wells)
    end

    Barcode = Struct.new(:top_line, :middle_line, :bottom_line, :round_label_top_line, :round_label_bottom_line, :barcode, :type)

    def tube_barcodes
      plate.tubes.map do |tube|
        Barcode.new(
          "P#{tube.aliquots.count} #{prioritized_name(tube.name, 10)} #{tube.label.prefix}",
          tube.label.text,
          date_today,
          tube.barcode.prefix,
          tube.barcode.number,
          tube.barcode.ean13,
          tube.barcode.type
        )
      end
    end
  end
end
