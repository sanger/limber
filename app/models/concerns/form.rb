# frozen_string_literal: true

module Form
  extend ActiveSupport::Concern
  included do
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

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
