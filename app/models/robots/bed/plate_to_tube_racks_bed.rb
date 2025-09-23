# frozen_string_literal: true

module Robots::Bed
  # This bed hosts the parent plate or a tube-rack. It uses the robot to find
  # its labware and child labware. When it is used as a source bed, it should
  # host the Plate. When it is used as a destination bed, it should host a
  # Tube Rack.
  #
  class PlateToTubeRacksBed < Robots::Bed::Base
    # Updates the metadata of the labware with the robot barcode.
    # This method is called inside the robot controller's start action for
    # Tube Racks and it sets the created_with_robot metadata field.
    #
    # @param robot_barcode [String] the robot barcode
    # @return [void]
    #
    def labware_created_with_robot(robot_barcode)
      # RobotController uses machine barcode for initialising LabwareMetadata
      # First write the robot barcode to the tube rack
      # This will be used if we verify barcode on the next bed verification
      # TODO: Add handling for JsonApiClient::Errors::NotFound error if barcode does not match a labware
      LabwareMetadata.new(user_uuid: user_uuid, barcode: labware.barcode.machine).update!(
        created_with_robot: robot_barcode
      )

      # Next write the robot barcode to the racked tubes in the tube rack
      # This is just so the tube (which can be used independently of the rack) also has a record
      # of the robot that created it
      # TODO: Add handling for JsonApiClient::Errors::NotFound error if barcode does not match a labware
      labware.racked_tubes.each do |racked_tube|
        LabwareMetadata.new(user_uuid: user_uuid, barcode: racked_tube.tube.barcode.machine).update!(
          created_with_robot: robot_barcode
        )
      end
    end

    # Returns an array of labware from the robot's labware store for barcodes.
    #
    # @return [Array<TubeRack>] child tube racks
    #
    def child_labware
      return [] if labware.blank?

      @child_labware ||= robot.child_labware(labware)
    end

    # Loads labware into this bed from the robot's labware store.
    #
    # @param barcodes [Array<String>] array containing the barcode of the labware
    # @return [void]
    #
    def load(barcodes)
      @barcodes = Array(barcodes).filter_map(&:strip).uniq
      @labware = @barcodes.present? ? robot.find_bed_labware(@barcodes) : []
    end

    # Changes the state of the labware to the target state. It will change the
    # state of all tubes of the tube-rack on this bed.
    #
    # @return [void]
    #
    def transition
      return if target_state.nil? || labware.nil? # We have nothing to do

      labware.racked_tubes.each { |racked_tube| change_tube_state(racked_tube.tube) }
    end

    # Changes the state of one tube to the target state. This method is called
    # by the transition method.
    #
    # @param tube [Tube] the tube for which the state should be changed
    def change_tube_state(tube)
      state_changer = StateChangers.lookup_for(tube.purpose.uuid)
      state_changer.new(tube.uuid, user_uuid).move_to!(target_state, "Robot #{robot.name} started")
    end
  end
end
