# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  class Base
    include Form
    include PlateWalking
    include NoCustomPage

    class_attribute :default_transfer_template_name
    self.attributes = %i[api purpose_uuid parent_uuid user_uuid]
    self.default_transfer_template_name = 'Transfer columns 1-12'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, presence: true

    attr_reader :child

    # The base creator is abstract, and is not intended to be used directly
    def self.support_parent?(_parent)
      false
    end

    def plate_to_walk
      parent
    end

    def child_purpose
      @child_purpose ||= api.plate_purpose.find(purpose_uuid)
    end

    def parent
      @parent ||= api.plate.find(parent_uuid)
    end
    alias plate parent

    def labware
      plate
    end

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    def purpose
      labware.plate_purpose
    end

    def label_text
      "#{labware.label.prefix} #{labware.label.text}"
    end

    def save!
      raise ResourceInvalid, self unless valid?
      create_labware!
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
      Settings.purposes.dig(purpose_uuid, :transfer_template) ||
        default_transfer_template_name
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

    private

    def transfer_template
      @template ||= api.transfer_template.find(transfer_template_uuid)
    end

    def create_plate_with_standard_transfer!
      plate_creation = create_plate_from_parent!
      @child = plate_creation.child
      transfer_material_from_parent!(@child.uuid)
      yield(@child) if block_given?
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
        user: user_uuid
      )
    end

    def create_labware!
      create_plate_with_standard_transfer!
    end
  end
end
