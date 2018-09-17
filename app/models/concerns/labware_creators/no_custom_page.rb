# frozen_string_literal: true

# By default forms need no special processing to they actually do the creation and then
# redirect.  If you have a special form to display include LabwareCreators::CustomPage
module LabwareCreators::NoCustomPage
  def render(controller)
    raise StandardError, "Not saving #{self.class} form...." unless save!

    controller.redirect_to_creator_child(self)
  end
end
