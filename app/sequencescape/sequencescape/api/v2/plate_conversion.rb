# frozen_string_literal: true

# plate conversion resource
class Sequencescape::Api::V2::PlateConversion < Sequencescape::Api::V2::Base
  has_one :parent, class_name: 'Sequencescape::Api::V2::Plate'
  has_one :purpose, class_name: 'Sequencescape::Api::V2::PlatePurpose'
  has_one :target, class_name: 'Sequencescape::Api::V2::Plate'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
