# frozen_string_literal: true

require_dependency 'forms'

module Forms
  class CreationForm
    module ClassMethods
      def class_for(purpose_uuid)
        Settings.purposes.fetch(purpose_uuid).fetch(:form_class).constantize
      end
    end
    extend ClassMethods

    include Form
    include PlateWalking

    self.attributes = %i(api purpose_uuid parent_uuid user_uuid)

    class_attribute :default_transfer_template_uuid
    self.default_transfer_template_uuid = Settings.transfer_templates['Transfer columns 1-12']

    attr_reader :plate_creation

    def plate_to_walk
      parent
    end

    validates(*attributes, presence: true)

    def child
      plate_creation.try(:child) || :child_not_created
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
      raise StandardError, 'Invalid data; ' + errors.full_messages.join('; ') unless valid?
      create_labware!
    end

    private

    def create_labware!(selected_transfer_template_uuid = default_transfer_template_uuid)
      @plate_creation = api.plate_creation.create!(
        parent: parent_uuid,
        child_purpose: purpose_uuid,
        user: user_uuid
      )

      api.transfer_template.find(selected_transfer_template_uuid).create!(
        source: parent_uuid,
        destination: @plate_creation.child.uuid,
        user: user_uuid
      )

      yield(@plate_creation.child) if block_given?
      true
    end
  end
end
