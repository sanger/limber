# frozen_string_literal: true

# show => Looks up the presenter for the given purpose and renders the appropriate show page
# update => Used to update the state of a plate/tube
# fail_wells => Updates the state of individual wells when failing
# Note: Finds plates via the v2 api
class PlatesController < LabwareController
  before_action :check_for_current_user!, only: %i[update fail_wells] # rubocop:todo Rails/LexicallyScopedActionFilter

  def fail_wells # rubocop:todo Metrics/AbcSize
    return redirect_to(limber_plate_path(params[:id]), notice: t('notices.no_wells_selected')) if selected_wells.empty?

    begin
      Sequencescape::Api::V2::StateChange.create!(
        contents: selected_wells,
        customer_accepts_responsibility: params[:customer_accepts_responsibility],
        reason: 'Individual Well Failure',
        target_state: 'failed',
        target_uuid: params[:id],
        user_uuid: current_user_uuid
      )
      redirect_to(limber_plate_path(params[:id]), notice: t('notices.wells_failed'))
    rescue StandardError => e
      log_plate_error(e)
      redirect_to limber_plate_path(params[:id]), alert: t('errors.messages.fail_wells_failed')
      nil
    end
  end

  def selected_wells
    params.fetch(:plate, {}).fetch(:wells, {}).select { |_, v| v == '1' }.keys
  end

  def process_mark_under_represented_wells # rubocop:todo Metrics/AbcSize
    return redirect_to(limber_plate_path(params[:id]), notice: no_wells_notice) if selected_wells.empty?

    begin
      plate = fetch_plate_with_requests(params[:id])
      mark_selected_wells_under_represented(plate)
      redirect_to(limber_plate_path(params[:id]), notice: t('notices.wells_marked_under_represented'))
    rescue StandardError => e
      log_plate_error(e)
      redirect_to limber_plate_path(params[:id]), alert: t('errors.messages.mark_wells_under_represented_failed')
      nil
    end
  end

  private

  def locate_labware_identified_by_id
    Sequencescape::Api::V2.plate_for_presenter(**search_param) ||
      raise(ActionController::RoutingError, "Unknown resource #{search_param}")
  end

  def fetch_plate_with_requests(plate_id)
    Sequencescape::Api::V2.plate_with_custom_includes('wells.aliquots.request', uuid: plate_id)
  end

  def mark_selected_wells_under_represented(plate)
    wells_by_location = plate.wells.index_by(&:location)
    selected_wells.each do |location|
      well = wells_by_location[location]
      create_poly_metadatum_for_request(well)
    end
  end

  def create_poly_metadatum_for_request(well)
    aliquot = well.aliquots.first
    # Get the request from the aliquot
    request = aliquot.request

    # If request is an array, get the first one?
    request = Array(request).first

    # Now `request` is the request object for that well
    # new a poly metadatum
    poly_metadatum = Sequencescape::Api::V2::PolyMetadatum.new(key: 'under_represented', value: 'true')
    # set the metadatable, link it to the request
    poly_metadatum.relationships.metadatable = request
    # save it
    poly_metadatum.save
  end

  def log_plate_error(exception)
    Rails.logger.error "#{exception.class}: #{exception.message}"
    Rails.logger.error "Backtrace:\n#{exception.backtrace.join("\n")}" if exception.respond_to?(:backtrace)
    return unless exception.respond_to?(:response) && exception.response

    Rails.logger.error "Response body: #{exception.response.body}"
  end
end
