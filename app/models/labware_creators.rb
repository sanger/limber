# frozen_string_literal: true

module LabwareCreators
  # Raised on validation errors. We should return false instead if these are
  # user error.
  class ResourceInvalid < StandardError
    def initialize(resource)
      super(resource.errors.full_messages.join('; '))
      @resource = resource
    end

    attr_reader :resource
  end

  def self.class_for(purpose_uuid)
    Settings.purposes.fetch(purpose_uuid).fetch(:creator_class).constantize
  end

  # Used to render the create plate/tube buttons
  class CreatorButton
    attr_accessor :parent_uuid, :purpose_uuid, :name, :type, :filters, :parent, :creator

    include ActiveModel::Model

    def default_method
      'post'
    end

    def model_name
      case type
      when 'plate' then ::ActiveModel::Name.new(Limber::Plate, nil, 'child')
      when 'tube' then ::ActiveModel::Name.new(Limber::Tube, nil, 'tube')
      else
        raise StandardError, "Unknown type #{type}"
      end
    end
  end

  # Used to render the create plate/tube buttons, separate class forces different template
  class CustomCreatorButton < CreatorButton
    def default_method
      'get'
    end
  end
end
