# frozen_string_literal: true

# show => Looks up the presenter for the given purpose and renders the appropriate show page
# update => Used to update the state of a plate/tube
# fail_wells => Updates the state of individual wells when failing
# Note: Finds plates via the v2 api
class PlatesController < LabwareController
  before_action :check_for_current_user!, only: %i[update fail_wells] # rubocop:todo Rails/LexicallyScopedActionFilter

  def fail_wells # rubocop:todo Metrics/AbcSize
    if wells_to_fail.empty?
      redirect_to(
        plate_path(params[:id]),
        notice: 'No wells were selected to fail' # rubocop:todo Rails/I18nLocaleTexts
      )
    else
      Sequencescape::Api::V2::StateChange.create!(
        contents: wells_to_fail,
        customer_accepts_responsibility: params[:customer_accepts_responsibility],
        reason: 'Individual Well Failure',
        target_state: 'failed',
        target_uuid: params[:id],
        user_uuid: current_user_uuid
      )
      redirect_to(
        plate_path(params[:id]),
        notice: 'Selected wells have been failed' # rubocop:todo Rails/I18nLocaleTexts
      )
    end
  end

  def wells_to_fail
    params.fetch(:plate, {}).fetch(:wells, {}).select { |_, v| v == '1' }.keys
  end

  private

  def locate_labware_identified_by_id
    Sequencescape::Api::V2.plate_for_presenter(**search_param) ||
      raise(ActionController::RoutingError, "Unknown resource #{search_param}")
  end
end
