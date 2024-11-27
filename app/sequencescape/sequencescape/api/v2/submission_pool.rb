# frozen_string_literal: true

# submission pool resource
class Sequencescape::Api::V2::SubmissionPool < Sequencescape::Api::V2::Base
  has_many :tag_layout_templates
end
