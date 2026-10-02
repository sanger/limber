# frozen_string_literal: true

# Adds tags to the wells of the plate itself, rather than to a new child plate,
# using the custom tagged plate page. Used when the tags are added to the same
# physical plate as the previous step, e.g. ULTP DNA Norm in the Ultima
# conversion pipelines.
#
# The presenter of the plate decides whether tags can be added (tagging_allowed?)
# and the state of the plate after the tags are added (tagged_state).
class Plates::TagLayoutsController < ApplicationController
  before_action :check_for_current_user!
  before_action :check_tagging_allowed

  def new
    @tags_per_well = purpose_config.fetch(:tags_per_well, 1)
    @tag_group_adapter_type_name_filter = purpose_config[:tag_group_adapter_type_name_filter].presence || 'Ultima'
  end

  # Responds to the custom tagged plate page with the page to redirect to.
  def create
    add_tags
    move_to_tagged_state

    render json: { redirect: plate_path(plate), message: 'Tags added, redirecting...' }
  end

  private

  def add_tags
    Sequencescape::Api::V2::TagLayout.create!(
      tag_layout_params.merge(plate_uuid: plate.uuid, user_uuid: current_user_uuid)
    )
  end

  def move_to_tagged_state
    StateChangers
      .lookup_for(plate.purpose.uuid)
      .new(plate.uuid, current_user_uuid)
      .move_to!(presenter.tagged_state, 'Tags added')
  end

  def plate
    @plate ||=
      Sequencescape::Api::V2.plate_for_presenter(uuid: params[:plate_id]) ||
      raise(ActionController::RoutingError, "Unknown resource #{params[:plate_id]}")
  end

  def presenter
    @presenter ||= Presenters.lookup_for(plate).new(labware: plate)
  end

  def purpose_config
    Settings.purposes.fetch(plate.purpose.uuid, {})
  end

  def check_tagging_allowed
    return if presenter.respond_to?(:tagging_allowed?) && presenter.tagging_allowed?

    message = 'Tags cannot be added to this plate in its current state.'
    respond_to do |format|
      format.html { redirect_to plate_path(plate), alert: message }
      format.json { render json: { message: [message] }, status: :bad_request }
    end
  end

  def tag_layout_params
    params
      .expect(
        plate: [
          {
            tag_layout: [
              :tag_group_uuid,
              :tag2_group_uuid,
              :direction,
              :walking_by,
              :initial_tag,
              :tags_per_well,
              { substitutions: {} }
            ]
          }
        ]
      )
      .fetch(:tag_layout)
      .to_h
      .compact_blank
  end
end
