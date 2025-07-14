# frozen_string_literal: true

module LabwareCreators # rubocop:todo Style/Documentation
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
    # While most creators have a creator_class assigned by default, this wasn't the case with tube racks
    # when first added. Here we fall back to 'LabwareCreators::Uncreatable' in cases where the purpose is
    # not fully configured
    refer = Settings.purposes.fetch(purpose_uuid, {}).fetch(:creator_class, 'LabwareCreators::Uncreatable')
    refer.is_a?(String) ? refer.constantize : refer[:name].constantize
  end

  def self.params_for(purpose_uuid)
    refer = Settings.purposes.fetch(purpose_uuid, {}).fetch(:creator_class, 'LabwareCreators::Uncreatable')
    return { params: {} } if refer.is_a?(String)

    { params: refer[:params] }
  end

  # Used to render the create plate/tube buttons
  class CreatorButton
    attr_accessor :parent_uuid, :purpose_uuid, :name, :type, :filters, :parent, :creator

    include ActiveModel::Model

    def custom_form?
      false
    end

    # plate_children (Plate -> Plate) (plate_creation#create)
    # plate_tubes (Plate -> Tube) (tube_creation#create)
    # tube_children (Tube -> Plate) (nothing - want to be plate_creation#create)
    # tube_tubes (Tube -> Tube) (tube_creation#create)
    def model_name
      case type
      when 'plate'
        ::ActiveModel::Name.new(Plate, nil, 'child_plate_creation')
      when 'tube'
        ::ActiveModel::Name.new(Tube, nil, 'child_tube_creation')
      else
        raise StandardError, "Unknown type #{type}"
      end
    end
  end

  # Used to render the create plate/tube buttons, separate class forces different template
  class CustomCreatorButton < CreatorButton
    def custom_form?
      true
    end
  end
end
