#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
class ApplicationController < ActionController::Base
  include Sequencescape::Api::Rails::ApplicationController
  delegate :api_connection_options, :to => 'IlluminaBPipeline::Application.config'

  protect_from_forgery

  def current_user_uuid
    session[:user_uuid]
  end

  helper_method :current_user_uuid

  def set_user_by_swipecard!(card_id)
    @current_user = user_for_swipecard(card_id)

    session[:user_uuid] = @current_user.uuid
  end

  def user_for_swipecard(card_id)
    user_search = api.search.find(Settings.searches["Find user by swipecard code"])

    user_search.first(:swipecard_code => card_id)
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, 'Sorry, that swipecard could not be found. Please try again or contact your administrator.'
  end

  def check_for_current_user!
    redirect_to(
      search_path,
      :alert => "You must be logged in to do that. Performing actions in multiple tabs can log you out."
    ) unless current_user_uuid.present?
  end
  private :check_for_current_user!
end
