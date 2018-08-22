# frozen_string_literal: true

class Sequencescape::Api::V2::Well < Sequencescape::Api::V2::Base
  has_many :qc_results
  has_many :requests_as_source, class_name: 'Sequencescape::Api::V2::Request'
  has_many :requests_as_target, class_name: 'Sequencescape::Api::V2::Request'
  has_many :downstream_assets, class_name: 'Sequencescape::Api::V2::Asset'
  has_many :aliquots

  def latest_concentration
    qc_results.select { |qc| qc.key.casecmp('molarity').zero? }
              .select { |qc| qc.units.casecmp('nM').zero? }
              .max_by(&:created_at)
  end

  def requests_in_progress
    aliquots.flat_map(&:request).compact
  end

  def location
    position['name']
  end

  def tagged?
    aliquots.any?(&:tagged?)
  end

  def passed?
    state == 'passed'
  end

  def active_requests
    requests_as_source + requests_in_progress
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

  def downstream_tubes
    downstream_assets.select(&:tube?)
  end
end
