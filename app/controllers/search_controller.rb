class SearchController < ApplicationController
  before_filter :clear_current_user!

  before_filter :check_for_login!, :only => [:create_or_find, :stock_plates ]

  def new
    @search_results = []
  end

  def ongoing_plates(search='Find Illumina-B plates')
    plate_search = api.search.find(Settings.searches[search])

    @search_results = plate_search.all(
      IlluminaB::Plate,
      :state => [ 'pending', 'started', 'passed', 'started_fx', 'started_mj', 'qc_complete' ]

    )
  end

  def ongoing_plates_illumina_a
    ongoing_plates('Find Illumina-A plates')
    render :ongoing_plates
  end

  def stock_plates_illumina_a
    stock_plates('Find Illumina-A stock plates')
    render :stock_plates
  end

  def my_plates
    plate_search    = api.search.find(Settings.searches['Find Illumina-B plates for user'])

    @search_results = plate_search.all(
      IlluminaB::Plate,
     :state     => [ 'pending', 'started', 'passed', 'started_fx', 'started_mj', 'qc_complete' ],
     :user_uuid => current_user_uuid
    )

    render :my_plates
  end

  def stock_plates(search='Find Illumina-B stock plates')
    plate_search    = api.search.find(Settings.searches[search])

    @search_results = plate_search.all(
      IlluminaB::Plate,
      :state     => [ 'pending', 'started', 'passed' ],
      :user_uuid => current_user_uuid
    )
  end

  def create_or_find
    params['show-my-plates'] == 'true' ? my_plates : create

  rescue => exception
    @search_results = []
    flash[:error]   = exception.message

    # rendering new without re-searching for the ongoing plates...
    respond_to do |format|
      format.html { render :new }
    end
  end

  def create
    raise "You have not supplied a labware barcode" if params[:plate_barcode].blank?

    respond_to do |format|
      format.html { redirect_to find_plate(params[:plate_barcode]) }
    end
  end

  def clear_current_user!
    session[:user_uuid] = nil
  end
  private :clear_current_user!

  def check_for_login!
    set_user_by_swipecard!(params[:card_id]) if params[:card_id].present?
  rescue Sequencescape::Api::ResourceNotFound => exception
    flash[:error] = exception.message
    redirect_to :search
  end
  private :check_for_login!

  def find_plate(barcode)
    api.search.find(Settings.searches['Find assets by barcode']).first(:barcode => barcode)
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, 'Sorry, could not find labware with the specified barcode.'
  end

  def retrieve_parent
    begin
      parent_plate = api.search.find(Settings.searches['Find source assets by destination asset barcode']).first(:barcode => params['barcode'])
      respond_to do |format|
        format.json { render :json => { :plate => { :parent_plate_barcode => parent_plate.barcode.ean13 }}}
      end
    rescue Sequencescape::Api::ResourceNotFound => exception
      respond_to do |format|
        format.json { render :json => {'general' => exception.message }, :status => 404}
      end
    end
  end

end
