# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012 Genome Research Ltd.
class CreationController < ApplicationController
  class_attribute :creation_message
  self.creation_message = 'Your new empty labware has been added to the system.'

  before_action :check_for_current_user!

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

  def new
    @creation_form = create_form(params.merge(parent_uuid: params[:limber_plate_id]))

    respond_to do |format|
      format.html { @creation_form.render(self) }
    end
  rescue Sequencescape::Api::ResourceInvalid => exception
    Rails.logger.error("Cannot create child plate of #{@creation_form.parent.uuid}")
    exception.backtrace.map(&Rails.logger.method(:error))

    respond_to do |format|
      format.html do
        redirect_to(
          limber_plate_path(@creation_form.parent),
          alert: ["Cannot create the plate: #{exception.message}", *exception.resource.errors.full_messages]
        )
      end
    end
  end

  def create
    @creation_form = create_form(params[:plate])

    @creation_form.save!
    respond_to do |format|
      format.html { redirect_to_form_destination(@creation_form) }
    end
  rescue => exception
    Rails.logger.error("Cannot create child plate of #{@creation_form.parent.uuid}")
    exception.backtrace.map(&Rails.logger.method(:error))

    respond_to do |format|
      format.html do
        redirect_to(
          limber_plate_path(@creation_form.parent),
          alert: "Cannot create the plate: #{exception.message}"
        )
      end
    end
  end
end
