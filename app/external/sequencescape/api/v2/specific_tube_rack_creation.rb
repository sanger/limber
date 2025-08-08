# frozen_string_literal: true

# Represents a specific tube rack creation in Limber via the Sequencescape API
class Sequencescape::Api::V2::SpecificTubeRackCreation < Sequencescape::Api::V2::Base
  has_many :children, class_name: 'Sequencescape::Api::V2::TubeRack'
  has_one :parent, class_name: 'Sequencescape::Api::V2::Plate'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
