# frozen_string_literal: true

# Represents a tube from plate creation in Limber via the Sequencescape API
# This is intended to be used for transferring samples from a plate well into two tubes,
# each for a well.
class Sequencescape::Api::V2::TubeFromPlateCreation < Sequencescape::Api::V2::Base
  has_one :child, class_name: 'Sequencescape::Api::V2::Tube'
  has_one :child_purpose, class_name: 'Sequencescape::Api::V2::TubePurpose'
  has_one :parent, class_name: 'Sequencescape::Api::V2::Plate'
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
end
