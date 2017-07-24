# frozen_string_literal: true

module LabwareCreators
  # Raised on validation errors. We shoudl return false instead if these are
  # user error.
  ResourceInvalid = Class.new(StandardError)

  def self.class_for(purpose_uuid)
    Settings.purposes.fetch(purpose_uuid).fetch(:form_class).constantize
  end
end
