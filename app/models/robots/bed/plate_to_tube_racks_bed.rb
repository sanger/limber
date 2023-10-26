# frozen_string_literal: true

module Robots::Bed
  # This bed hosts the parent plate or a tube-rack. It uses the robot to find
  # its labware and child labware. When it is used as a source bed, it should
  # host the Plate. When it is used as a destination bed, it should host a
  # tube-rack wrapper.
  #
  class PlateToTubeRacksBed < Robots::Bed::Base
    # Updates the metadata of the labware with the robot barcode.
    # This method is called inside the robot controller's start action for
    # tube-rack wrappers and it sets the created_with_robot metadata field.
    #
    # @param [String] robot_barcode the robot barcode
    # @return [void]
    #
    def labware_created_with_robot(robot_barcode)
      labware.tubes.each do |tube|
        LabwareMetadata
          .new(api: api, user: user_uuid, barcode: tube.barcode.machine)
          .update!(created_with_robot: robot_barcode)
      end
    end

    # Returns an array of labware from the robot's labware store for barcodes.
    #
    # @return [Array<TubeRackWrapper>] child tube-rack wrappers
    #
    def child_labware
      return [] if labware.blank?

      @child_labware ||= robot.child_labware(labware)
    end

    # Loads labware into this bed from the robot's labware store.
    #
    # @param [Array<String>] barcodes array containing the barcode of the labware
    # @return [void]
    #
    def load(barcodes)
      @barcodes = Array(barcodes).filter_map(&:strip).uniq
      @labware = @barcodes.present? ? robot.find_bed_labware(@barcodes) : []
    end
  end
end
