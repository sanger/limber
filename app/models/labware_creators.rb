# frozen_string_literal: true

module LabwareCreators
  def self.class_for(purpose_uuid)
    Settings.purposes.fetch(purpose_uuid).fetch(:form_class).constantize
  end
end
