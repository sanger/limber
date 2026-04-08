# frozen_string_literal: true

# Represents a plate creation in Limber via the Sequencescape API
class Sequencescape::Api::V2::PlateCreation < Sequencescape::Api::V2::Base
  has_one :child, class_name: 'Sequencescape::Api::V2::Plate'
  has_one :child_purpose, class_name: 'Sequencescape::Api::V2::PlatePurpose'
  has_one :parent, class_name: 'Sequencescape::Api::V2::Plate'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
