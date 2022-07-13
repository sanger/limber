# frozen_string_literal: true

# Smaller level grouping of work than a Submission
# for building requests, and downstream labware and receptacles.
class Sequencescape::Api::V2::Order < Sequencescape::Api::V2::Base
  property :created_at, type: :time
  property :updated_at, type: :time
end
