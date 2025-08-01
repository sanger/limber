# frozen_string_literal: true

# Handles log in / log out
class SessionsController < ApplicationController
  def create
    self.user_swipecard = params.require(:user_swipecard)
    if @current_user
      redirect_to :search, notice: 'Logged in' # rubocop:todo Rails/I18nLocaleTexts
    else
      redirect_to :search,
                  alert: 'Sorry, that swipecard could not be found. Please update your details in Sequencescape.' # rubocop:todo Rails/I18nLocaleTexts
    end
  end

  def destroy
    reset_session
    cookies[:user_name] = nil
    cookies[:user_id] = nil
    redirect_to :search, notice: 'Logged out' # rubocop:todo Rails/I18nLocaleTexts
  end

  private

  def user_swipecard=(card_id)
    @current_user = user_for_swipecard(card_id)
    return if @current_user.nil?

    session[:user_uuid] = @current_user.uuid
    session[:user_name] = @current_user.name

    # Unlike the session cookie, this cookie is accessible
    # through javascript.
    cookies[:user_name] = @current_user.name
    cookies[:user_id] = @current_user.id
  end

  def user_for_swipecard(card_id)
    Sequencescape::Api::V2::User.find(user_code: card_id).first
  end
end
