# frozen_string_literal: true

# show => Looks up the presenter for the given purpose and renders the appropriate show page
# update => Used to update the state of a plate/tube
# fail_wells => Updates the state of individual wells when failing
# Note: Finds tubes via the v2 api
class TubeRacksController < LabwareController
  before_action :check_for_current_user!, only: %i[update] # rubocop:todo Rails/LexicallyScopedActionFilter

  private

  def locate_labware_identified_by_id
    Sequencescape::Api::V2.tube_rack_for_presenter(search_param) ||
      raise(ActionController::RoutingError, "Unknown resource #{search_param}")
  end
end
