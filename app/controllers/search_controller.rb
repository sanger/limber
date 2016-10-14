#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.
class SearchController < ApplicationController

  class InputError < StandardError; end

  before_action :clear_current_user!, :except => [:qcables]

  before_action :check_for_login!, :only => [:create_or_find, :stock_plates ]

  def new
    @search_results = []
  end

  ## REVIEW: It needs to set the correct ongoing_plate_searching parameter
  def ongoing_plates(search='Find Illumina-B plates')
    plate_search = api.search.find(Settings.searches[search])
    states = [ 'pending', 'started', 'passed', 'started_fx', 'started_mj', 'qc_complete', 'nx_in_progress']

    @search_results = plate_search.all(
      Limber::Plate,
      :state => states,
     :user_uuid => current_user_uuid
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
    plate_search    = api.search.find(Settings.searches['Find plates for user'])
    states = [ 'pending', 'started', 'passed', 'started_fx', 'started_mj', 'qc_complete', 'nx_in_progress']

    @search_results = plate_search.all(
      Limber::Plate,
     :state     => states,
     :user_uuid => current_user_uuid
    )

    render :my_plates
  end

  def stock_plates(search='Find Illumina-B stock plates')
    plate_search    = api.search.find(Settings.searches[search])
    states = ['pending', 'started', 'passed', 'qc_complete']

    @search_results = plate_search.all(
      Limber::Plate,
      :state     => states,
      :user_uuid => current_user_uuid
    )
  end

  def qcables
    raise InputError, "You have not supplied a barcode" if params[:qcable_barcode].blank?
    pruned_barcode = params[:qcable_barcode].strip
    raise InputError, "#{params[:qcable_barcode]} is not a valid barcode" unless /^[0-9]{13}$/===pruned_barcode
    respond_to do |format|
      format.json {
          redirect_to find_qcable(pruned_barcode)
      }
    end
  rescue Sequencescape::Api::ResourceNotFound, InputError => exception
    render :json => {'error' => exception.message }
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
    # session[:user_uuid] = nil unless request.accepts.include?('application/json')
  end
  private :clear_current_user!

  def find_plate(barcode)
    api.search.find(Settings.searches['Find assets by barcode']).first(:barcode => barcode)
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, 'Sorry, could not find labware with the specified barcode.'
  end

  def find_qcable(barcode)
    api.search.find(Settings.searches['Find qcable by barcode']).first(:barcode => barcode)
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, 'Sorry, could not find qcable with the specified barcode.'
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
