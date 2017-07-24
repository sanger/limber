# frozen_string_literal: true

#
# Module NestedValidators provides an ActiveModel compatible
# version of validates associated. Unlike the active model
# version however it actually propagates the error outwards.
#
# Usage:
#
# class MyHappyClass
#   extend NestedValidators
#
#   validates_nested :my_other_active_model_object
#
# end
#
module NestedValidation
  class NestedValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      Array(value).each do |nested|
        next if nested.valid?
        nested.errors.each do |nested_attribute, nested_error|
          record.errors.add("#{attribute}.#{nested_attribute}", nested_error)
        end
      end
    end
  end

  def validates_nested(*attr_names)
    validates_with NestedValidator, _merge_attributes(attr_names)
  end
end
