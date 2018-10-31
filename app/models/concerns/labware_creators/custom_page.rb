# frozen_string_literal: true

# A labware creator with a custom page requires user
# input before a piece of labware can be created.
module LabwareCreators::CustomPage
  extend ActiveSupport::Concern

  class_methods do
    def creator_button(parameters)
      LabwareCreators::CustomCreatorButton.new(parameters)
    end
  end
end
