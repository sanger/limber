# frozen_string_literal: true

# By default forms need no special processing to they actually do the creation and then
# redirect.  If you have a special form to display include LabwareCreators::CustomPage
module LabwareCreators::NoCustomPage
  extend ActiveSupport::Concern

  class_methods do
    def creator_button(parameters)
      LabwareCreators::CreatorButton.new(parameters)
    end
  end
end
