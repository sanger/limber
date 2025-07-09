# frozen_string_literal: true

# Involved in creation of plates
# Controllers find the appropriate LabwareCreator specified by the purpose configuration
# new => renders the form specified by the labware creator,
#        This usually indicates that further information needs to be supplied by the user,
#        or that we need to display an interstitial page
# create => Use the specified labware creator to generate the resource. Will usually redirect
#           to the asset that has just been created, but may redirect to the parent if there are multiple children.
class PlateCreationController < CreationController
  def redirection_path(form)
    polymorphic_path(form.redirection_target, anchor: form.anchor)
  end

  private

  def creator_params
    params.require(:plate)
  end
end
