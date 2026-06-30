# frozen_string_literal: true

# submission template resource
class Sequencescape::Api::V2::SubmissionTemplate < Sequencescape::Api::V2::Base
  def self.find_by(uuid:)
    where(uuid:).first
  end
end
