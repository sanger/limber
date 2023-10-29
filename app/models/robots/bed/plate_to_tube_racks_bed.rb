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
      # RobotController uses machine barcode for initialising LabwareMetadata
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

    # Changes the state of the labware to the target state. It will change the
    # state of all tubes of the tube-rack on this bed.
    #
    # @return [void]
    #
    def transition
      return if target_state.nil? || labware.nil? # We have nothing to do

      labware.tubes.each { |tube| change_tube_state(tube) }
    end

    # Changes the state of one tube to the target state. This method is called
    # by the transition method.
    #
    # @param [Tube] tube the tube
    def change_tube_state(tube)
      state_changer = StateChangers.lookup_for(tube.purpose.uuid)
      state_changer.new(api, tube.uuid, user_uuid).move_to!(target_state, "Robot #{robot.name} started")
    end
  end
end
