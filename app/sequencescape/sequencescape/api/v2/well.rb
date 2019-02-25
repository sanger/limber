# frozen_string_literal: true

class Sequencescape::Api::V2::Well < Sequencescape::Api::V2::Base
  has_many :qc_results
  has_many :requests_as_source, class_name: 'Sequencescape::Api::V2::Request'
  has_many :requests_as_target, class_name: 'Sequencescape::Api::V2::Request'
  has_many :downstream_assets, class_name: 'Sequencescape::Api::V2::Asset'
  has_many :downstream_tubes, class_name: 'Sequencescape::Api::V2::Tube'
  has_many :downstream_wells, class_name: 'Sequencescape::Api::V2::Well'
  has_many :downstream_plates, class_name: 'Sequencescape::Api::V2::Plate'
  has_many :aliquots

  def latest_concentration
    qc_results.select { |qc| qc.key.casecmp('molarity').zero? }
              .select { |qc| qc.units.casecmp('nM').zero? }
              .max_by(&:created_at)
  end

  def requests_in_progress
    aliquots.flat_map(&:request).compact
  end

  def coordinate
    WellHelpers.well_coordinate(location)
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
