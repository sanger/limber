# frozen_string_literal: true

class CreationController < ApplicationController
  before_action :check_for_current_user!

  def form_lookup(form_attributes = params)
    LabwareCreators::Base.class_for(form_attributes.fetch(:purpose_uuid))
  end

  def redirect_to_form_destination(form)
    redirect_to(
      redirection_path(form),
      notice: 'New empty labware added to the system.'
    )
  end

  def create_form(form_attributes)
    form_lookup(form_attributes).new(
      form_attributes.merge(
        api: api,
        user_uuid: current_user_uuid
      )
    )
  end
end
