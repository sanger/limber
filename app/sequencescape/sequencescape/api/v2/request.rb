# frozen_string_literal: true

class Sequencescape::Api::V2::Request < Sequencescape::Api::V2::Base
  belongs_to :request_type
  belongs_to :submission
  belongs_to :order
  belongs_to :primer_panel

  delegate :for_multiplexing, to: :request_type

  def passed?
    state == 'passed'
  end

  def pcr_cycles
    options['pcr_cycles']
  end
end
