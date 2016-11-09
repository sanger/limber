# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013 Genome Research Ltd.
module Forms
  module Form
    module CustomPage
      # We need to do something special at this point in order to create the plate.
      def render(controller)
        controller.render(page)
      end
    end

    module NoCustomPage
      # By default forms need no special processing to they actually do the creation and then
      # redirect.  If you have a special form to display include Forms::Form::CustomPage
      def render(controller)
        raise StandardError, "Not saving #{self.class} form...." unless save!
        controller.redirect_to_form_destination(self)
      end
    end

    def self.included(base)
      base.class_eval do
        extend ActiveModel::Naming
        include ActiveModel::Conversion
        include ActiveModel::Validations
        include NoCustomPage

        class_attribute :page
        self.page = 'new'

        class_attribute :aliquot_partial
        self.aliquot_partial = 'labware/aliquot'

        class_attribute :attributes
      end
    end

    # We should probablu use active model mosel, but need to clean up some forms
    def initialize(attributes = {})
      self.attributes.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end
    end

    def method_missing(name, *args, &block)
      name_without_assignment = name.to_s.sub(/=$/, '').to_sym
      return super unless attributes.include?(name_without_assignment)

      instance_variable_name = :"@#{name_without_assignment}"
      return instance_variable_get(instance_variable_name) if name_without_assignment == name.to_sym
      instance_variable_set(instance_variable_name, args.first)
    end
    protected :method_missing

    def persisted?
      false
    end
  end

  class CreationForm
    include Form
    include PlateWalking

    self.attributes = [:api, :purpose_uuid, :parent_uuid, :user_uuid]

    class_attribute :default_transfer_template_uuid
    self.default_transfer_template_uuid = Settings.transfer_templates['Transfer columns 1-12']

    attr_reader :plate_creation

    def plate_to_walk
      parent
    end

    validates presence: { attributes }

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

      create_objects!
    end

    def create_plate!(selected_transfer_template_uuid = default_transfer_template_uuid)
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
    private :create_plate!

    alias create_objects! create_plate!
  end
end
