# frozen_string_literal: true

module Form
  extend ActiveSupport::Concern

  module CustomPage
    # We need to do something special at this point in order to create the plate.
    def render(controller)
      controller.render(page)
    end
  end

  module NoCustomPage
    # By default forms need no special processing to they actually do the creation and then
    # redirect.  If you have a special form to display include Form::CustomPage
    def render(controller)
      raise StandardError, "Not saving #{self.class} form...." unless save!
      controller.redirect_to_creator_child(self)
    end
  end

  included do
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

  # We should probably use active model model, but need to clean up some forms
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

  def respond_to_missing?(name, include_private = false)
    name_without_assignment = name.to_s.sub(/=$/, '').to_sym
    attributes.include?(name_without_assignment) ||
      super
  end

  def persisted?
    false
  end
end
