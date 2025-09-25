# frozen_string_literal: true

# Created from the tutorial at https://www.mintbit.com/blog/custom-404-500-error-pages-in-rails/

# This controller is responsible for rendering custom error pages
#
# User authentication is skipped for a faster response and to allow these pages
# to be accessible without a logged-in user.
#
# The layout is set to false to avoid rendering the application layout.
#
# All actions provide responses in HTML format, even if the request ends in a
# different format like .json or .png.
class ErrorsController < ApplicationController
  layout false

  # 404 Not Found
  def not_found
    render template: 'errors/error', status: :not_found, formats: [:html]
  end

  # 406 Not Acceptable
  def not_acceptable
    render template: 'errors/error', status: :not_acceptable, formats: [:html]
  end

  # 500 Internal Server Error
  def internal_server_error
    render template: 'errors/error', status: :internal_server_error, formats: [:html]
  end

  # 503 Service Unavailable
  def service_unavailable
    render template: 'errors/error', status: :service_unavailable, formats: [:html]
  end
end
