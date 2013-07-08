class TubeCreationController < CreationController

  def form_lookup(form_attributes = params)
    Settings.purposes[form_attributes[:purpose_uuid]][:form_class].constantize
  end

  def redirection_path(form)
    illumina_b_tube_path(form.child.uuid)
  end


  def new
    @creation_form = create_form(params.merge(:parent_uuid => params[:sequencescape_tube_id]))

    respond_to do |format|
      format.html { @creation_form.render(self) }
    end

  rescue Sequencescape::Api::ResourceInvalid => exception
    Rails.logger.error("Cannot create child tube from #{@creation_form.parent.uuid}")
    exception.backtrace.map(&Rails.logger.method(:error))

    respond_to do |format|
      format.html do
        redirect_to(
          sequencescape_tube_path(@creation_form.parent),
          :alert =>[  "Cannot create tube: #{exception.message}", *exception.resource.errors.full_messages ]
        )
      end
    end
  end

  def create
    @creation_form = create_form(params[:tube])

    @creation_form.save!
    respond_to do |format|
      format.html { redirect_to_form_destination(@creation_form) }
    end
  rescue => exception
    Rails.logger.error("Cannot create child tube of #{@creation_form.parent.uuid}")
    exception.backtrace.map(&Rails.logger.method(:error))

    respond_to do |format|
      format.html do
        redirect_to(
          sequencescape_tube_path(@creation_form.parent),
          :alert => "Cannot create tube: #{exception.message}"
        )
      end
    end
  end
end
