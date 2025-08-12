# frozen_string_literal: true

# A Lot from sequencescape via the V2 API
class Sequencescape::Api::V2::Lot < Sequencescape::Api::V2::Base
  has_one :lot_type

  # The template is is a polymorphic relationship in Sequencescape, but we only want to access the UUID
  # and so we don't need a specific class since all properties are accessible via the base class.
  has_one :template, class_name: 'Sequencescape::Api::V2::Base'
end
