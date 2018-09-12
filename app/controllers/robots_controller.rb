# frozen_string_literal: true

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

  def start
    @robot.perform_transfer(stripped_beds)
    if params[:robot_barcode].present?
      @robot.beds.each_value do |bed|
        next unless bed.transitions? && bed.plate
        PlateMetadata.new(api: api, user: current_user_uuid, plate: bed.plate, created_with_robot: params[:robot_barcode]).update
      end
    end
    respond_to do |format|
      format.html do
        redirect_to search_path,
                    notice: "Robot #{@robot.name} has been started."
      end
    end
  rescue Robots::Robot::Bed::BedError => exception
    # Our beds complained, nothing has happened.
    respond_to do |format|
      format.html { redirect_to robot_path(id: @robot.id), notice: "#{exception.message} No plates have been started." }
    end
  end

  def verify
    render(json: @robot.verify(stripped_beds, params[:robot_barcode]))
  end

  private

  def find_robot
    @robot = Robots.find(
      id: params[:id],
      api: api,
      user_uuid: current_user_uuid
    )
  end

  def stripped_beds
    {}.tap do |stripped|
      (params[:beds] || params[:bed] || {}).each do |k, v|
        stripped[k.strip] = stripped_plates(v)
      end
    end
  end

  def stripped_plates(plates)
    return plates.strip if plates.respond_to?(:strip) # We have a string
    return plates.map(&:strip) if plates.respond_to?(:map) # We have an array
    plates # No idea, but lets be optimistic!
  end

  def validate_beds
    return true if params['bed'].present?
    redirect_to robot_path(id: robot.id), notice: "We didn't receive any bed information"
    false
  end
end
