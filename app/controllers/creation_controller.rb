# frozen_string_literal: true

# Base class for labware creation. Inherited by PlateCreationController and TubeCreationController.
# Controllers find the appropriate LabwareCreator specified by the purpose configuration
# new => renders the form specified by the labware creator,
#        This usually indicates that further information needs to be supplied by the user,
#        or that we need to display an interstitial page
# create => Use the specified labware creator to generate the resource. Will usually redirect
#           to the asset that has just been created, but may redirect to the parent if there are multiple children.
class CreationController < ApplicationController
  before_action :check_for_current_user!
  rescue_from LabwareCreators::ResourceInvalid, with: :creation_failed

  def new
    params[:parent_uuid] ||= parent_uuid
    @labware_creator = labware_creator(params.permit(permitted_attributes))
    respond_to { |format| format.html { render(@labware_creator.page) } }
  end

  def create
    creator_params[:parent_uuid] ||= parent_uuid
    @labware_creator = labware_creator(creator_params)
    @labware_creator.save ? create_success : create_failure
  end

  def labware_creator(form_attributes)
    creator_class.new(form_attributes.permit(permitted_attributes).merge(params_for_creator_build))
  end

  def creation_failed(exception)
    Rails.logger.error("Cannot create child of #{@labware_creator.parent.uuid}")
    Rails.logger.error(exception.message)
    exception.backtrace.map(&Rails.logger.method(:error)) # rubocop:todo Performance/MethodObjectAsBlock

    redirect_back_after_error('Cannot create the next piece of labware:', exception.resource.errors.full_messages)
  end

  private

  def create_success
    respond_to do |format|
      format.json do
        render json: { redirect: redirection_path(@labware_creator), message: 'Plate created, redirecting...' }
      end
      format.html do
        redirect_to redirection_path(@labware_creator), notice: 'New empty labware added to the system.' # rubocop:todo Rails/I18nLocaleTexts
      end
    end
  end

  def create_failure # rubocop:todo Metrics/AbcSize
    Rails.logger.error(@labware_creator.errors.full_messages)
    respond_to do |format|
      format.json { render json: { message: @labware_creator.errors.full_messages }, status: :bad_request }
      format.html do
        flash.now.alert = @labware_creator.errors.full_messages
        render @labware_creator.page
      end
    end
  end

  def permitted_attributes
    creator_class.attributes
  end

  def creator_class
    @creator_class ||= LabwareCreators.class_for(params_purpose_uuid)
  end

  def params_for_creator_build
    LabwareCreators.params_for(params_purpose_uuid).merge({ user_uuid: current_user_uuid })
  end

  def params_purpose_uuid
    params[:purpose_uuid] || creator_params.fetch(:purpose_uuid)
  end

  def parent_uuid
    params[:tube_id] || params[:plate_id] || params[:tube_rack_id]
  end

  def redirect_back_after_error(prefix_message, error_messages)
    flash_messages = [prefix_message] + Array(error_messages)
    respond_to do |format|
      format.html do
        redirect_back(fallback_location: url_for(@labware_creator.parent), alert: truncate_flash(flash_messages))
      end
    end
  end
end
