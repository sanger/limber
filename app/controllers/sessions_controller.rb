# frozen_string_literal: true
class SessionsController < ApplicationController
  def create
    set_user_by_swipecard!(params[:user_swipecard]) if params[:user_swipecard].present?
    redirect_to :search, notice: 'Logged in'
  rescue Sequencescape::Api::ResourceNotFound => exception
    flash[:error] = exception.message
    redirect_to :search, alert: exception.message
  end

  def destroy
    reset_session
    redirect_to :search, notice: 'Logged out'
  end

  private

  def set_user_by_swipecard!(card_id)
    @current_user = user_for_swipecard(card_id)
    session[:user_uuid] = @current_user.uuid
    session[:user_name] = @current_user.name
  end

  def user_for_swipecard(card_id)
    user_search = api.search.find(Settings.searches['Find user by swipecard code'])

    user_search.first(swipecard_code: card_id)
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, 'Sorry, that swipecard could not be found. Please try again or contact your administrator.'
  end

  def check_for_current_user!
    redirect_to(
      search_path,
      alert: 'You must be logged in to do that. Performing actions in multiple tabs can log you out.'
    ) unless current_user_uuid.present?
  end
end
