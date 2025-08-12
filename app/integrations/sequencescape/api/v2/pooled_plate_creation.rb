# frozen_string_literal: true

# Represents a pooled plate creation in Limber via the Sequencescape API
class Sequencescape::Api::V2::PooledPlateCreation < Sequencescape::Api::V2::Base
  has_one :child, class_name: 'Sequencescape::Api::V2::Plate'
  has_many :parents, class_name: 'Sequencescape::Api::V2::Labware'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
