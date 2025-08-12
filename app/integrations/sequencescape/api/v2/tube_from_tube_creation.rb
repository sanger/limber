# frozen_string_literal: true

# Represents a tube from tube creation in Limber via the Sequencescape API
class Sequencescape::Api::V2::TubeFromTubeCreation < Sequencescape::Api::V2::Base
  has_one :child, class_name: 'Sequencescape::Api::V2::Tube'
  has_one :child_purpose, class_name: 'Sequencescape::Api::V2::TubePurpose'
  has_one :parent, class_name: 'Sequencescape::Api::V2::Tube'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
