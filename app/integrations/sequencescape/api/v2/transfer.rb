# frozen_string_literal: true

# transfer resource
class Sequencescape::Api::V2::Transfer < Sequencescape::Api::V2::Base
  has_one :destination, class_name: 'Sequencescape::Api::V2::Labware'
  has_one :source, class_name: 'Sequencescape::Api::V2::Labware'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
