# frozen_string_literal: true

# Handles robot validation
# The id parameter indicates which robot is being used
# The controller looks up the current settings in Setting.robots[id]
# These settings are currently compiled from robots.rb
# Robot.find_robot generates a new robot based on the matching settings
# On each controller action a Robot is initialized based on the sett
# show => renders the form for the selected robot
# verify => Checks that the robot has been set up correctly, and returns any problems to the user
# start => Starts the robot, and transitions the plates to the configured states
class RobotsController < ApplicationController
  before_action :find_robot
  before_action :validate_beds, only: :start
  before_action :check_for_current_user!, only: [:start]

  def show
    respond_to do |format|
      format.html { render 'show', locals: { robot: @robot } }
      format.csv
    end
  end

  # rubocop:todo Metrics/MethodLength
  def start # rubocop:todo Metrics/AbcSize
    @robot.perform_transfer(stripped_beds)
    if params[:robot_barcode].present?
      @robot.beds.each_value do |bed|
        next unless bed.transitions? && bed.labware

        labware_barcode = bed.labware.barcode.machine
        begin
          LabwareMetadata.new(
            api: api,
            user: current_user_uuid,
            barcode: labware_barcode
          ).update!(created_with_robot: params[:robot_barcode])
        rescue Sequencescape::Api::ResourceNotFound
          respond_to do |format|
            format.html { redirect_to robot_path(id: @robot.id), notice: "Plate #{plate_barcode} not found." }
          end
        end
      end
    end
    respond_to do |format|
      format.html do
        redirect_to search_path,
                    notice: "Robot #{@robot.name} has been started."
      end
    end
  rescue Robots::Bed::BedError => e
    # Our beds complained, nothing has happened.
    respond_to do |format|
      format.html { redirect_to robot_path(id: @robot.id), notice: "#{e.message} No plates have been started." }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def verify
    render(json: @robot.verify(robot_params))
  end

  private

  def robot_params
    params.permit(:robot_barcode, bed_labwares: {})
  end

  def find_robot
    @robot = Robots.find(
      id: params[:id],
      api: api,
      user_uuid: current_user_uuid
    )
  end

  def stripped_beds
    {}.tap do |stripped|
      (params[:bed_labwares] || {}).each do |k, v|
        stripped[k.strip] = stripped_labware_barcodes(v)
      end
    end
  end

  def stripped_labware_barcodes(bed_labware)
    return bed_labware.strip if bed_labware.respond_to?(:strip) # We have a string
    return bed_labware.map(&:strip) if bed_labware.respond_to?(:map) # We have an array

    bed_labware # No idea, but lets be optimistic!
  end

  def validate_beds
    return true if params['bed_labwares'].present?

    redirect_to robot_path(id: @robot.id), notice: "We didn't receive any bed information"
    false
  end
end
