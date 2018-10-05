# frozen_string_literal: true

require_dependency 'limber/user'

# Handles log in / log out
class SessionsController < ApplicationController
  def create
    self.user_swipecard = params.require(:user_swipecard)
    redirect_to :search, notice: 'Logged in'
  rescue Sequencescape::Api::ResourceNotFound => exception
    redirect_to :search, alert: exception.message
  end

  def destroy
    reset_session
    cookies[:user_name] = nil
    redirect_to :search, notice: 'Logged out'
  end

  private

  def user_swipecard=(card_id)
    @current_user = user_for_swipecard(card_id)
    session[:user_uuid] = @current_user.uuid
    session[:user_name] = @current_user.name
    # Unlike the session cookie, this cookie is accessible
    # through javascript.
    cookies[:user_name] = @current_user.name
  end

  def user_for_swipecard(card_id)
    user_search = api.search.find(Settings.searches['Find user by swipecard code'])
    user_search.first(swipecard_code: card_id)
  rescue Sequencescape::Api::ResourceNotFound => exception
    raise exception, 'Sorry, that swipecard could not be found. Please update your details in Sequencescape.'
  end
end
