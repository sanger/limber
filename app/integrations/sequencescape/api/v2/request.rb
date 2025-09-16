# frozen_string_literal: true

# Represents a request in Limber via the Sequencescape API
class Sequencescape::Api::V2::Request < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasPolyMetadata

  FragmentSize = Struct.new(:from, :to)

  has_one :request_type
  has_one :submission
  has_one :order
  has_one :request_metadata, class_name: 'Sequencescape::Api::V2::RequestMetadata'
  has_one :primer_panel, class_name: 'Sequencescape::Api::V2::PrimerPanel'

  delegate :for_multiplexing, to: :request_type
  delegate :key, to: :request_type, prefix: true

  property :state, type: :string_inquirer

  delegate :pending?, :started?, :passed?, :failed?, :cancelled?, to: :state, allow_nil: true

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
