# frozen_string_literal: true

class CreationController < ApplicationController
  before_action :check_for_current_user!
  rescue_from Sequencescape::Api::ResourceInvalid, LabwareCreators::ResourceInvalid, with: :creation_failed

  def new
    params[:parent_uuid] ||= parent_uuid
    @labware_creator = labware_creator(params.permit(permitted_attributes))
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
    creator_class.new(api,
                      form_attributes.permit(permitted_attributes).merge(
                        user_uuid: current_user_uuid
                      ))
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

  private

  def permitted_attributes
    creator_class.attributes
  end

  def creator_class
    @creator_class ||= LabwareCreators.class_for(params[:purpose_uuid] || creator_params.fetch(:purpose_uuid))
  end
end
