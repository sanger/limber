class SearchController < ApplicationController
  before_filter :clear_current_user

  def new
    begin
    raise "You're a loudmouth baby! You better shut it up!"
    rescue => exception
      ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
    end
    collect_all_ongoing_plates
  end

  def all_outstanding_plates
    collect_all_outstanding_plates
    render :new
  end


  def create
    raise "You have not supplied a plate barcode" if params[:plate_barcode].blank?

    set_user_by_swipecard!(params[:card_id]) if params[:card_id].present?

    respond_to do |format|
      format.html { redirect_to find_plate(params[:plate_barcode]) }
    end

  rescue => exception
    @ongoing       = []
    flash[:alert] = exception.message

    # rendering new without researching for the ongoing plates...
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
    plate_search = api.search.find(Settings.searches['Find pulldown plates'])
    @ongoing = plate_search.all(Pulldown::Plate, :state => [ 'pending', 'started', 'passed' ])
  end
  private :collect_all_ongoing_plates

  def clear_current_user
    session[:user_uuid] = nil
  end
  private :clear_current_user

  def find_plate(barcode)
    api.search.find(Settings.searches['Find assets by barcode']).first(:barcode => barcode)
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, 'Could not find the plate with the specified barcode'
  end

end
