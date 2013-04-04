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
    robot.perform_transfer(params['bed'])
  end

  def find_robot
    @robot = Robots::Robot.find(
      :name=>params[:id],
      :api=>api
    )
  end
  private :find_robot

end
