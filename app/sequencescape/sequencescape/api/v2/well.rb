# frozen_string_literal: true

class Sequencescape::Api::V2::Well < Sequencescape::Api::V2::Base
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

  def latest_concentration
    latest_qc(key: 'concentration', units: 'ng/ul')
  end

  def latest_molarity
    latest_qc(key: 'molarity', units: 'nM')
  end

  def latest_qc(key:, units:)
    qc_results.to_a # Convert to array to resolve any api queries. Otherwise select fails to work.
              .select { |qc| qc.key.casecmp(key).zero? }
              .select { |qc| qc.units.casecmp(units).zero? }
              .max_by(&:created_at)
  end

  def requests_in_progress
    aliquots.flat_map(&:request).compact
  end

  def in_progress_submission_uuids
    requests_in_progress.flat_map(&:submission_uuid)
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
    aliquots.blank?
  end

  def passed?
    state == 'passed'
  end

  def failed?
    state == 'failed'
  end

  # Shows the requests currently active.
  # We pre-filter cancelled requests as we tend to treat them as though they never existed
  # We then prioritise any in progress requests over those which have passed.
  # Generally, processing passed requests is a bad idea, but can be useful in
  # rare circumstances. We warn the user if they are trying to do this.
  def active_requests
    completed, in_progress = associated_requests.partition(&:completed?)
    in_progress.presence || completed
  end

  def incomplete_requests
    associated_requests.reject(&:completed?)
  end

  def multiple_requests?
    active_requests.many?
  end

  def associated_requests
    (requests_as_source + requests_in_progress).reject(&:cancelled?)
  end

  def for_multiplexing
    active_requests.any?(&:for_multiplexing)
  end

  def any_complete_requests?
    active_requests.any?(&:passed?)
  end

  def suboptimal?
    aliquots.any?(&:suboptimal)
  end

  def pcr_cycles
    active_requests.map(&:pcr_cycles).uniq
  end

  def role
    active_requests.detect(&:role)&.role
  end

  def priority
    active_requests.map(&:priority).max || 0
  end

  def submission_ids
    active_requests.map(&:submission_id).uniq
  end

  def pool_id
    submission_ids.first
  end
end
