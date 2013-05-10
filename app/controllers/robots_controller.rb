class RobotsController < ApplicationController

  attr_reader :robot
  before_filter :find_robot

  def show
    respond_to do |format|
      format.html { render 'show', :locals => {:robot => @robot }}
      format.csv
    end
  end

  def start
    begin
      robot.perform_transfer(params['bed'])
      respond_to do |format|
        format.html {
          redirect_to search_path,
          :notice => "Robot #{robot.name} has been started."
        }
      end
    rescue Robots::Robot::Bed::BedError => exception
      # Our beds complained, nothing has happened.
      respond_to do |format|
        format.html { redirect_to robot_path(robot.name), :notice=> "#{exception.message} No plates have been started." }
      end
    end
  end

  def verify
    respond_to do |format|
      format.json { render( :json=> @robot.verify(params[:beds]||{}) ) }
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

end
