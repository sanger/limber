class CreationController < ApplicationController
  class_inheritable_reader :creation_message
  write_inheritable_attribute :creation_message, 'Your lab ware has been created'

  def redirect_to_form_destination(form)
    redirect_to(redirection_path(form), :notice => creation_message)
  end

  def create_form(form_attributes)
    form_lookup(form_attributes).new(form_attributes.merge(:api => api))
  end

  def new
    @creation_form = create_form(params.merge(:parent_uuid => params[:pulldown_plate_id]))

    respond_to do |format|
      format.html { @creation_form.render(self) }
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
          :notice => "Cannot create the plate: #{exception.message}"
        )
      end
    end
  end
end
