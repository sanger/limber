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
        limber_plate_path(params[:id]),
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
        limber_plate_path(params[:id]),
        notice: 'Selected wells have been failed' # rubocop:todo Rails/I18nLocaleTexts
      )
    end
  end

  def wells_to_fail
    params.fetch(:plate, {}).fetch(:wells, {}).select { |_, v| v == '1' }.keys
  end

  def mark_under_represented_wells
    if wells_to_mark.empty?
      redirect_to(
        limber_plate_path(params[:id]),
        notice: 'No wells were selected to mark as under-represented'
      )
    else
      # create record in poly metadata 
      # type: request, key: under_represented, value: true
    
      plate = Sequencescape::Api::V2.plate_with_custom_includes(['wells.aliquots.request'], uuid: params[:id])
      wells_by_location = plate.wells.index_by(&:location)
     
      # for each well, find the aliquot and then the request
      # create a new poly metadatum for the request
      well = wells_by_location[wells_to_mark.first]
      aliquot = well.aliquots.first
      # Get the request from the aliquot
      request = aliquot.request

      # If request is an array, get the first one?
      request = Array(request).first
    
      # Now `request` is the request object for that well
      # new a poly metadatum
      poly_metadatum = Sequencescape::Api::V2::PolyMetadatum.new(
        key: 'under_represented',
        value: 'true'
      )
      # set the metadatable, link it to the request
      poly_metadatum.relationships.metadatable = request
      # save it
      poly_metadatum.save

      redirect_to(
        limber_plate_path(params[:id]),
        notice: 'Selected wells have been marked as under-represented'
      )
    end
  end

  def wells_to_mark
    params.fetch(:plate, {}).fetch(:wells, {}).select { |_, v| v == '1' }.keys
  end

  private

  def locate_labware_identified_by_id
    Sequencescape::Api::V2.plate_for_presenter(**search_param) ||
      raise(ActionController::RoutingError, "Unknown resource #{search_param}")
  end
end
