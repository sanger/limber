class SearchController < ApplicationController
  before_filter :clear_current_user

  def new
    collect_all_ongoing_plates
  end

  def all_outstanding_plates
    collect_all_outstanding_plates
    render :new
  end


  def create
    raise "You have not supplied a plate barcode" if params[:plate_barcode].blank?

    find_user

    respond_to do |format|
      format.html { redirect_to api.search.find(Settings.searches['Find assets by barcode']).first(:barcode => params[:plate_barcode]) }
    end


  rescue Sequencescape::Api::ResourceNotFound => exception
    @ongoing       = []
    flash[:notice] = 'Could not find the plate with the specified barcode'

    respond_to do |format|
      format.html { render :new }
    end
  rescue => exception
    @ongoing       = []
    flash[:notice] = exception.message

    respond_to do |format|
      format.html { render :new }
    end
  end

  def collect_all_outstanding_plates
    plate_search = api.search.find(Settings.searches['Find pulldown plates'])
    @ongoing = plate_search.all(
      Pulldown::Plate,
      :state => [ 'pending', 'started', 'passed', 'cancelled', 'failed' ]
    )
  end
  private :collect_all_outstanding_plates

  def collect_all_ongoing_plates
    @ongoing = api.search.find(Settings.searches['Find pulldown plates']).all(Pulldown::Plate, :state => [ 'pending', 'started', 'passed' ])
  end
  private :collect_all_ongoing_plates

  def clear_current_user
    session[:user_uuid] = nil
  end
  private :clear_current_user

  def find_user
    return if params[:user_id].blank?
    session[:user_uuid] = find_user_by_swipecard(params[:user_id])
  end
  private :find_user

end
