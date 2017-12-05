# frozen_string_literal: true

module LabwareCreators
  # Raised on validation errors. We shoudl return false instead if these are
  # user error.
  class ResourceInvalid < StandardError
    def initialize(resource)
      super('Invalid data; ' + resource.errors.full_messages.join('; '))
      @resource = resource
    end

    attr_reader :resource
  end

  def self.class_for(purpose_uuid)
    Settings.purposes.fetch(purpose_uuid).fetch(:creator_class).constantize
  end
end
