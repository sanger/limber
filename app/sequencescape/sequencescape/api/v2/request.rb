# frozen_string_literal: true

class Sequencescape::Api::V2::Request < Sequencescape::Api::V2::Base
  delegate :for_multiplexing, to: :request_type

  def passed?
    state == 'passed'
  end

  def pcr_cycles
    options['pcr_cycles']
  end

  def submission_id
    relationships.submission.dig(:data, :id)
  end
end
