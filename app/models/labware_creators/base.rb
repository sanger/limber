# frozen_string_literal: true

require './lib/nested_validation'

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  class Base # rubocop:todo Style/Documentation
    include Form
    include PlateWalking
    include NoCustomPage

    extend NestedValidation

    attr_reader :api, :child
    attr_accessor :purpose_uuid, :parent_uuid, :user_uuid

    class_attribute :default_transfer_template_name, :style_class, :state

    self.attributes = %i[purpose_uuid parent_uuid user_uuid]
    self.default_transfer_template_name = 'Transfer columns 1-12'
    self.style_class = 'creator'
    # Used when rendering plates. Mostly set to pending as we're usually rendering a new plate.
    self.state = 'pending'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :transfer_template_name, presence: true

    # The base creator is abstract, and is not intended to be used directly
    def self.support_parent?(_parent)
      false
    end

    # We pull out the api as the first argument as it ensures
    # we'll always have it available, even during assignment of
    # other attributes. Otherwise we end up relying on hash order.
    def initialize(api, *args)
      @api = api
      super(*args)
    end

    def plate_to_walk
      parent
    end

    def labware
      parent
    end

    def save!
      save || raise(ResourceInvalid, self)
    end

    def save
      valid? && create_labware!
    end

    #
    # The name of the transfer template which will be used.
    # In post cases this will be the default transfer template
    # but it can be overridden by specifying a custom template
    # in the purpose config.
    #
    # @return [<String] The name of the transfer template which will be used.
    #
    def transfer_template_name
      purpose_config.fetch(:transfer_template, default_transfer_template_name)
    end

    #
    # The uuid of the transfer template to be used.
    # Extracted from the transfer template cache base on the name
    #
    # @return [String] UUID
    #
    def transfer_template_uuid
      Settings.transfer_templates.fetch(transfer_template_name)
    end

    #
    # The object which we cant to redirect the user to after the creator
    # has been saved. If you've created a single entity, this should probably
    # be the child, so that's what we return by default
    #
    # @return [Object] Object that supports url_for(object)
    def redirection_target
      child
    end

    def anchor
      'summary_tab'
    end

    #
    # The name of the child purpose.
    #
    # @return [String] The purpose name
    #
    def purpose_name
      purpose_config.name
    end

    private

    # rubocop:todo Naming/MemoizedInstanceVariableName
    def transfer_template
      @template ||= api.transfer_template.find(transfer_template_uuid)
    end
    # rubocop:enable Naming/MemoizedInstanceVariableName

    def create_plate_with_standard_transfer!
      plate_creation = create_plate_from_parent!
      @child = plate_creation.child
      transfer_material_from_parent!(@child.uuid)
      yield(@child) if block_given?
      after_transfer!
      true
    end

    def create_plate_from_parent!
      api.plate_creation.create!(
        parent: parent_uuid,
        child_purpose: purpose_uuid,
        user: user_uuid
      )
    end

    def transfer_material_from_parent!(child_uuid)
      transfer_template.create!(
        source: parent_uuid,
        destination: child_uuid,
        user: user_uuid,
        transfers: transfer_hash
      )
    end

    # Override in classes with custom transfers
    def transfer_hash
      nil
    end

    def create_labware!
      create_plate_with_standard_transfer!
    end

    def purpose_config
      Settings.purposes.fetch(purpose_uuid, {})
    end

    # Override in classes that need to implement behaviour ater transfers
    def after_transfer!
      true
    end
  end
end
