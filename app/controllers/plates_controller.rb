# frozen_string_literal: true

# show => Looks up the presenter for the given purpose and renders the appropriate show page
# update => Used to update the state of a plate/tube
# fail_wells => Updates the state of individual wells when failing
# Note: Finds plates via the v2 api
class PlatesController < LabwareController
  # AJAX endpoint to search for a Project by id using Sequencescape API
  def find_project_by_id
    project_id = params[:project_id]
    begin
      project = Sequencescape::Api::V2::Project.find!(project_id)
      # Ensure we return both id and uuid for clarity
      render json: { found: true,
                     project: { id: project.first.id, uuid: project.first.uuid, name: project.first.name,
                                state: project.first.state } }
    rescue JsonApiClient::Errors::NotFound
      render json: { found: false, error: 'Project not found' }, status: :not_found
    rescue StandardError => e
      render json: { found: false, error: e.message }, status: :internal_server_error
    end
  end
  before_action :check_for_current_user!, only: %i[update fail_wells] # rubocop:todo Rails/LexicallyScopedActionFilter

  def fail_wells # rubocop:todo Metrics/AbcSize
    return redirect_to_no_wells_selected if selected_wells.empty?

    begin
      Sequencescape::Api::V2::StateChange.create!(
        contents: selected_wells,
        customer_accepts_responsibility: params[:customer_accepts_responsibility],
        reason: 'Individual Well Failure',
        target_state: 'failed',
        target_uuid: params[:id],
        user_uuid: current_user_uuid
      )
      redirect_to(plate_path(params[:id]), notice: t('notices.wells_failed'))
    rescue StandardError => e
      log_plate_error(e)
      redirect_to plate_path(params[:id]), alert: t('errors.messages.fail_wells_failed')
    end
  end

  def selected_wells
    params.fetch(:plate, {}).fetch(:wells, {}).select { |_, v| v == '1' }.keys
  end

  def process_mark_under_represented_wells
    return redirect_to_no_wells_selected if selected_wells.empty?

    mark_wells_under_represented_and_redirect
  end

  private

  def locate_labware_identified_by_id
    Sequencescape::Api::V2.plate_for_presenter(**search_param) ||
      raise(ActionController::RoutingError, "Unknown resource #{search_param}")
  end

  def fetch_plate_with_poly_metadata(plate_id)
    # fetch with poly-metadata included, so we can check for plate/wells already having
    # under-represented metadata, and avoid attempting to create duplicates
    Sequencescape::Api::V2.plate_with_custom_includes(
      'poly_metadata,wells.poly_metadata',
      uuid: plate_id
    )
  end

  def mark_wells_under_represented_and_redirect
    plate = fetch_plate_with_poly_metadata(params[:id])
    mark_selected_plate_under_represented(plate)
    mark_selected_wells_under_represented(plate)
    redirect_to(plate_path(params[:id]), notice: t('notices.wells_marked_under_represented'))
  rescue StandardError => e
    log_plate_error(e)
    redirect_to plate_path(params[:id]), alert: t('errors.messages.mark_wells_under_represented_failed')
  end

  # Marks the plate with under-represented metadata
  # This is to make the lookup in Sequencescape for ancestor plates with under-represented wells
  # more efficient, so we don't have to traverse all ancestor plate wells
  # @param plate [Sequencescape::Api::V2::Plate] the plate to mark
  def mark_selected_plate_under_represented(plate)
    # Check if the plate already has under-represented metadata
    plate_already_under_represented = false
    if plate.poly_metadata.present?
      plate_already_under_represented = plate.poly_metadata.any? do |pm|
        pm.key == LimberConstants::UNDER_REPRESENTED_KEY
      end
    end

    return if plate_already_under_represented

    Sequencescape::Api::V2::PolyMetadatum.create!(
      key: LimberConstants::UNDER_REPRESENTED_KEY,
      value: 'true',
      relationships: { metadatable: plate }
    )
  end

  # Marks the wells with under-represented metadata
  # @param plate [Sequencescape::Api::V2::Plate] the plate containing the wells to mark
  def mark_selected_wells_under_represented(plate)
    wells_by_location = plate.wells.index_by(&:location)
    selected_wells.each do |location|
      well = wells_by_location[location]
      create_poly_metadatum_for_well(well)
    end
  end

  def create_poly_metadatum_for_well(well)
    # Check if the well already has under-represented metadata
    well_already_under_represented = false
    if well.poly_metadata.present?
      well_already_under_represented = well.poly_metadata.any? do |pm|
        pm.key == LimberConstants::UNDER_REPRESENTED_KEY
      end
    end

    # binding.pry if well_already_under_represented
    return if well_already_under_represented

    Sequencescape::Api::V2::PolyMetadatum.create!(
      key: LimberConstants::UNDER_REPRESENTED_KEY,
      value: 'true',
      relationships: { metadatable: well }
    )
  end

  def log_plate_error(exception)
    return unless exception.respond_to?(:response) && exception.response

    Rails.logger.error "Response body: #{exception.response.body}"
  end

  def redirect_to_no_wells_selected
    redirect_to(plate_path(params[:id]), alert: t('errors.messages.no_wells_selected'))
  end
end
