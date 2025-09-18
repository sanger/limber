# frozen_string_literal: true

# Represents a state change in Limber via the Sequencescape API
class Sequencescape::Api::V2::StateChange < Sequencescape::Api::V2::Base
  has_one :target, class_name: 'Sequencescape::Api::V2::Labware'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
