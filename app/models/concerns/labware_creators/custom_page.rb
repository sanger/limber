# A labware creator with a custom page requires user
# input before a piece of labware can be created.
module LabwareCreators::CustomPage
  # We need to do something special at this point in order to create the plate.
  def render(controller)
    controller.render(page)
  end
end
