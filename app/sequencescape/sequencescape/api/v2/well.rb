# frozen_string_literal: true

class Sequencescape::Api::V2::Well < Sequencescape::Api::V2::Base # rubocop:todo Style/Documentation
  include Sequencescape::Api::V2::Shared::HasRequests
  include Sequencescape::Api::V2::Shared::HasPolyMetadata

  has_many :qc_results
  has_many :requests_as_source, class_name: 'Sequencescape::Api::V2::Request'
  has_many :requests_as_target, class_name: 'Sequencescape::Api::V2::Request'
  has_many :downstream_assets, class_name: 'Sequencescape::Api::V2::Asset'
  has_many :downstream_tubes, class_name: 'Sequencescape::Api::V2::Tube'
  has_many :downstream_wells, class_name: 'Sequencescape::Api::V2::Well'
  has_many :downstream_plates, class_name: 'Sequencescape::Api::V2::Plate'

  has_many :upstream_assets, class_name: 'Sequencescape::Api::V2::Asset'
  has_many :upstream_tubes, class_name: 'Sequencescape::Api::V2::Tube'
  has_many :upstream_wells, class_name: 'Sequencescape::Api::V2::Well'
  has_many :upstream_plates, class_name: 'Sequencescape::Api::V2::Plate'
  has_many :aliquots, class_name: 'Sequencescape::Api::V2::Aliquot'

  has_many :transfer_requests_as_source, class_name: 'Sequencescape::Api::V2::TransferRequest'
  has_many :transfer_requests_as_target, class_name: 'Sequencescape::Api::V2::TransferRequest'

  property :state, type: :string_inquirer

  delegate :pending?, :started?, :passed?, :failed?, :cancelled?, to: :state

  def latest_concentration
    latest_qc(key: 'concentration', units: 'ng/ul')
  end

  def latest_molarity
    latest_qc(key: 'molarity', units: 'nM')
  end

  def latest_live_cell_count
    latest_qc(key: 'live_cell_count', units: 'cells/ml')
  end

  def latest_total_cell_count
    latest_qc(key: 'total_cell_count', units: 'cells/ml')
  end

  def latest_cell_viability
    latest_qc(key: 'viability', units: '%')
  end

  def latest_qc(key:, units:)
    qc_results
      .to_a # Convert to array to resolve any api queries. Otherwise select fails to work.
      .select { |qc| qc.key.casecmp(key).zero? }
      .select { |qc| qc.units.casecmp(units).zero? }
      .max_by(&:created_at)
  end

  def all_latest_qc
    qc_results.sort_by(&:id).index_by(&:key).values
  end

  def coordinate
    WellHelpers.well_coordinate(location)
  end

  def quadrant_index
    WellHelpers.well_quadrant(location)
  end

  def location
    position['name']
  end

  def tagged?
    aliquots.any?(&:tagged?)
  end

  def empty?
    aliquots.blank? || aliquots.empty?
  end

  def inactive?
    empty? || failed? || cancelled?
  end

  def suboptimal?
    aliquots.any?(&:suboptimal)
  end

  def sanger_sample_id
    aliquots.first.sample.sanger_sample_id
  end

  def supplier_name
    aliquots.first.sample.sample_metadata.supplier_name
  end

  def input_amount_available
    molarity = latest_molarity&.value
    return unless molarity

    molarity.to_f * 25
  end

  def contains_control?
    return true if aliquots[0]&.sample&.control

    false
  end

  def control_info
    aliquots[0]&.sample&.control_type
  end

  def control_info_formatted
    return nil unless contains_control?

    case control_info
    when 'positive', 'pcr positive'
      '+'
    when 'negative', 'pcr negative', 'lysate negative'
      '-'
    else
      'c' # control of unspecified type
    end
  end

  def order_group
    aliquots.map(&:order_group).uniq
  end
end
