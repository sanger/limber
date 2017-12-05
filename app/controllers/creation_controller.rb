# frozen_string_literal: true

class CreationController < ApplicationController
  before_action :check_for_current_user!
  rescue_from Sequencescape::Api::ResourceInvalid, LabwareCreators::ResourceInvalid, with: :creation_failed

  def creator_for(form_attributes = params)
    LabwareCreators.class_for(form_attributes.fetch(:purpose_uuid))
  end

  def new
    params[:parent_uuid] ||= parent_uuid
    @creator_form = creator_form(params)

    respond_to do |format|
      format.html { @creator_form.render(self) }
    end
  end

  def redirect_to_creator_child(creator)
    redirect_to(
      redirection_path(creator),
      notice: 'New empty labware added to the system.'
    )
  end

  def creator_form(form_attributes)
    creator_for(form_attributes).new(
      form_attributes.merge(
        api: api,
        user_uuid: current_user_uuid
      )
    )
  end

  def creation_failed(exception)
    Rails.logger.error("Cannot create child of #{@creator_form.parent.uuid}")
    exception.backtrace.map(&Rails.logger.method(:error))

    respond_to do |format|
      format.html do
        redirect_back(
          fallback_location: url_for(@creator_form.parent),
          alert: ["Cannot create the next piece of labware:", *exception.resource.errors.full_messages]
        )
      end
    end
  end
end
