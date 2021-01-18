# frozen_string_literal: true

# show => Looks up the presenter for the given purpose and renders the appropriate show page
# update => Used to update the state of a plate/tube
# fail_wells => Updates the state of individual wells when failing
# Note: Finds plates via the v2 api
class PlatesController < LabwareController
  before_action :check_for_current_user!, only: %i[update fail_wells] # rubocop:todo Rails/LexicallyScopedActionFilter

  # rubocop:todo Metrics/MethodLength
  def fail_wells # rubocop:todo Metrics/AbcSize
    if wells_to_fail.empty?
      redirect_to(limber_plate_path(params[:id]), notice: 'No wells were selected to fail')
    else
      api.state_change.create!(
        user: current_user_uuid,
        target: params[:id],
        contents: wells_to_fail,
        target_state: 'failed',
        reason: 'Individual Well Failure',
        customer_accepts_responsibility: params[:customer_accepts_responsibility]
      )
      redirect_to(limber_plate_path(params[:id]), notice: 'Selected wells have been failed')
    end
  end
  # rubocop:enable Metrics/MethodLength

  def wells_to_fail
    params.fetch(:plate, {}).fetch(:wells, {}).select { |_, v| v == '1' }.keys
  end

  private

  def locate_labware_identified_by_id
    Sequencescape::Api::V2.plate_for_presenter(search_param) ||
      raise(ActionController::RoutingError, "Unknown resource #{search_param}")
  end

  def locate_additional_labwares_by_barcode
    return nil unless search_additional_labwares_param
    # TODO: check that this is returning a list
    Sequencescape::Api::V2.additional_plates_for_presenter(search_additional_labwares_param) ||
      raise(ActionController::RoutingError, "Unknown resource #{search_additional_labwares_param}")
  end
end
