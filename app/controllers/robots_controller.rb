class RobotsController < ApplicationController

  attr_reader :robot
  before_filter :find_robot
  before_filter :validate_beds, :only => :start

  def show
    respond_to do |format|
      format.html { render 'show', :locals => {:robot => @robot }}
      format.csv
    end
  end

  def start
    begin
      robot.perform_transfer(stripped_beds)
      respond_to do |format|
        format.html {
          redirect_to search_path,
          :notice => "Robot #{robot.name} has been started."
        }
      end
    rescue Robots::Robot::Bed::BedError => exception
      # Our beds complained, nothing has happened.
      respond_to do |format|
        format.html { redirect_to robot_path(:id=>robot.id,:location=>robot.location), :notice=> "#{exception.message} No plates have been started." }
      end
    end
  end

  def verify
    respond_to do |format|
      format.json { render( :json=> @robot.verify(stripped_beds) ) }
    end
  end

  def find_robot
    @robot = Robots::Robot.find(
      :id        =>params[:id],
      :location  =>params[:location],
      :api       =>api,
      :user_uuid => current_user_uuid
    )
  end
  private :find_robot

  def stripped_beds
    Hash[(params[:beds]||params[:bed]||{}).map {|k,v| [k.strip,v.strip]}]
  end
  private :stripped_beds

  def validate_beds
    return true if params['bed'].present?
    redirect_to robot_path(:id=>robot.id,:location=>robot.location), :notice=> "We didn't receive any bed information"
    false
  end
  private :validate_beds
end
