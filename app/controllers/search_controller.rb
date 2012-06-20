class SearchController < ApplicationController
  before_filter :clear_current_user

  def new
    @ongoing       = []
  end

  def all_outstanding_plates
    collect_all_outstanding_plates
    render :new
  end

  def all_my_plates
    collect_all_user_plates
    render :new
  end

  def all_stock_plates
    collect_all_stock_plates
    render :new
  end

  def create_or_find
    params[:show_my_plates] ? all_my_plates : create
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

  def collect_all_user_plates
    set_user_by_swipecard!(params[:card_id]) if params[:card_id].present?
    plate_search = api.search.find(Settings.searches['Find Illumina-B plates for user'])
    @ongoing = plate_search.all(IlluminaB::Plate, :state => [ 'pending', 'started', 'passed' ], :user_uuid => current_user_uuid)
  end
  private :collect_all_user_plates

  def collect_all_stock_plates
    set_user_by_swipecard!(params[:card_id]) if params[:card_id].present?
    plate_search = api.search.find(Settings.searches['Find Illumina-B stock plates'])
    @ongoing = plate_search.all(IlluminaB::Plate, :state => [ 'pending', 'started', 'passed' ], :user_uuid => current_user_uuid)
  end
  private :collect_all_stock_plates

  def collect_all_outstanding_plates
    plate_search = api.search.find(Settings.searches['Find Illumina-B plates'])
    @ongoing = plate_search.all(
      IlluminaB::Plate,
      :state => [ 'pending', 'started', 'passed', 'cancelled', 'failed' ]
    )
  end
  private :collect_all_outstanding_plates

  def collect_all_ongoing_plates
    plate_search = api.search.find(Settings.searches['Find Illumina-B plates'])
    @ongoing = plate_search.all(IlluminaB::Plate, :state => [ 'pending', 'started', 'passed' ])
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
