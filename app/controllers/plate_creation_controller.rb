# frozen_string_literal: true

class PlateCreationController < CreationController
  def redirection_path(form)
    limber_plate_path(form.child.uuid)
  end

  def new
    @creation_form = create_form(params.merge(parent_uuid: params[:limber_plate_id]))
    respond_to do |format|
      format.html { @creation_form.render(self) }
    end
  rescue Sequencescape::Api::ResourceInvalid, LabwareCreators::ResourceInvalid => exception
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
  rescue Sequencescape::Api::ResourceInvalid, LabwareCreators::ResourceInvalid => exception
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
