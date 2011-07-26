class CreationController < ApplicationController
  class_inheritable_reader :creation_message
  write_inheritable_attribute :creation_message, 'Your lab ware has been created'


  before_filter :check_for_current_user!

  def redirect_to_form_destination(form)
    redirect_to(redirection_path(form), :notice => creation_message)
  end

  def create_form(form_attributes)
    form_lookup(form_attributes).new(
      form_attributes.merge(
        :api       => api,
        :user_uuid => current_user_uuid
      )
    )
  end

  def new
    @creation_form = create_form(params.merge(:parent_uuid => params[:pulldown_plate_id]))

    respond_to do |format|
      format.html { @creation_form.render(self) }
    end
  rescue Sequencescape::Api::ResourceInvalid => exception
    Rails.logger.error("Cannot create child plate of #{@creation_form.parent.uuid}")
    exception.backtrace.map(&Rails.logger.method(:error))

    respond_to do |format|
      format.html do
        redirect_to(
          pulldown_plate_path(@creation_form.parent),
          :alert =>[  "Cannot create the plate: #{exception.message}", *exception.resource.errors.full_messages ]
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
          pulldown_plate_path(@creation_form.parent),
          :alert => "Cannot create the plate: #{exception.message}"
        )
      end
    end
  end

  def check_for_current_user!
    redirect_to(
      search_path,
      :alert => "Please login before creating plates."
    ) unless current_user_uuid.present?
  end
  private :check_for_current_user!
end
