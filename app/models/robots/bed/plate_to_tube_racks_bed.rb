# frozen_string_literal: true

module Robots::Bed
  # Plate to tube racks robot beds
  class PlateToTubeRacksBed < Robots::Bed::Base
    # TODO: Do I need this accessor?
    attr_accessor :parents

    def labware_created_with_robot(robot_barcode)
      labware.tubes.each do |tube|
        LabwareMetadata
          .new(api: api, user: user_uuid, barcode: tube.barcode.machine)
          .update!(created_with_robot: robot_barcode)
      end
    end

    def child_labware
      return [] if labware.blank?

      @child_labware ||= robot.child_labware(labware)
    end

    def load(barcodes)
      @barcodes = Array(barcodes).filter_map(&:strip).uniq
      @labware = @barcodes.present? ? robot.find_bed_labware(@barcodes) : []
    end
  end
end
