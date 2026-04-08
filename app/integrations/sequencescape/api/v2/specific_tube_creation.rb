# frozen_string_literal: true

# Represents a specific tube creation in Limber via the Sequencescape API
class Sequencescape::Api::V2::SpecificTubeCreation < Sequencescape::Api::V2::Base
  has_many :children, class_name: 'Sequencescape::Api::V2::Tube'
  has_many :parents, class_name: 'Sequencescape::Api::V2::Labware'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
