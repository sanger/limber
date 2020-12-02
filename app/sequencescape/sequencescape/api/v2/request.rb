# frozen_string_literal: true

class Sequencescape::Api::V2::Request < Sequencescape::Api::V2::Base # rubocop:todo Style/Documentation
  FragmentSize = Struct.new(:from, :to)

  has_one :submission
  has_one :order

  delegate :for_multiplexing, to: :request_type
  delegate :key, to: :request_type, prefix: true

  def passed?
    state == 'passed'
  end

  def failed?
    state == 'failed'
  end

  def cancelled?
    state == 'cancelled'
  end

  def completed?
    passed? || failed?
  end

  def passable?
    !(cancelled? || completed?)
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

  def submission_uuid
    submission&.uuid
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
