# frozen_string_literal: true

class CreationController < ApplicationController
  before_action :check_for_current_user!
  rescue_from Sequencescape::Api::ResourceInvalid, LabwareCreators::ResourceInvalid, with: :creation_failed

  def creator_for(form_attributes = params)
    LabwareCreators.class_for(form_attributes.fetch(:purpose_uuid))
  end

  def new
    params[:parent_uuid] ||= parent_uuid
    @labware_creator = labware_creator(params)
    respond_to do |format|
      format.html { @labware_creator.render(self) }
    end
  end

  def redirect_to_creator_child(creator)
    redirect_to(
      redirection_path(creator),
      notice: 'New empty labware added to the system.'
    )
  end

  def labware_creator(form_attributes)
    creator_for(form_attributes).new(
      form_attributes.merge(
        api: api,
        user_uuid: current_user_uuid
      )
    )
  end

  def creation_failed(exception)
    Rails.logger.error("Cannot create child of #{@labware_creator.parent.uuid}")
    exception.backtrace.map(&Rails.logger.method(:error))

    respond_to do |format|
      format.html do
        redirect_back(
          fallback_location: url_for(@labware_creator.parent),
          alert: ['Cannot create the next piece of labware:', *exception.resource.errors.full_messages]
        )
      end
    end
  end
end
