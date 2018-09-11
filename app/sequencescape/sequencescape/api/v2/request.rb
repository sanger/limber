# frozen_string_literal: true

class Sequencescape::Api::V2::Request < Sequencescape::Api::V2::Base
  FragmentSize = Struct.new(:from, :to)

  delegate :for_multiplexing, to: :request_type

  def passed?
    state == 'passed'
  end

  def pcr_cycles
    options['pcr_cycles']
  end

  def library_type
    options['library_type']
  end

  def fragment_size
    FragmentSize.new(options['fragment_size_required_from'], options['fragment_size_required_to'])
  end

  def submission_id
    relationships.submission.dig(:data, :id)
  end

  def order_id
    relationships.order.dig(:data, :id)
  end

  # Determines which requests get grouped together for the
  # purposes of displaying pool information
  def group_identifier
    pre_capture_pool&.id || order_id
  end
end
