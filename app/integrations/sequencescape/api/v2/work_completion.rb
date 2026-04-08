# frozen_string_literal: true

# A WorkCompletion can be used to pass library creation requests.
# It will also link the upstream and downstream requests to the correct receptacles.
class Sequencescape::Api::V2::WorkCompletion < Sequencescape::Api::V2::Base
  has_one :user, class_name: 'Sequencescape::Api::V2::User'
  has_one :target, class_name: 'Sequencescape::Api::V2::Labware'
  has_many :submissions, class_name: 'Sequencescape::Api::V2::Submission'
end
