# frozen_string_literal: true

class TubeCreationController < CreationController
  def redirection_path(form)
    url_for(form.child)
  end

  def new
    @creation_form = create_form(params.merge(parent_uuid: params[:limber_tube_id]))

    respond_to do |format|
      format.html { @creation_form.render(self) }
    end
  rescue Sequencescape::Api::ResourceInvalid => exception
    Rails.logger.error("Cannot create child tube from #{@creation_form.parent.uuid}")
    exception.backtrace.map(&Rails.logger.method(:error))

    respond_to do |format|
      format.html do
        redirect_to(
          limber_tube_path(@creation_form.parent),
          alert: ["Cannot create tube: #{exception.message}", *exception.resource.errors.full_messages]
        )
      end
    end
  end

  def create
    tube_params[:parent_uuid] ||= params[:limber_tube_id]
    @creation_form = create_form(tube_params)
    @creation_form.save!
    respond_to do |format|
      format.html { redirect_to_form_destination(@creation_form) }
    end
  rescue Sequencescape::Api::ResourceInvalid => exception
    Rails.logger.error("Cannot create child tube of #{@creation_form.parent.uuid}")
    exception.backtrace.map(&Rails.logger.method(:error))

    respond_to do |format|
      format.html do
        redirect_to(
          limber_tube_path(@creation_form.parent),
          alert: "Cannot create tube: #{exception.message}"
        )
      end
    end
  end

  def tube_params
    params.require(:tube)
  end
end
