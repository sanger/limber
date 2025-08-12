# frozen_string_literal: true

# A class representing receptacles coming from the SequenceScape JSON API.
class Sequencescape::Api::V2::Receptacle < Sequencescape::Api::V2::Base
  has_many :requests_as_source, class_name: 'Sequencescape::Api::V2::Request'
  has_many :qc_results, class_name: 'Sequencescape::Api::V2::QcResult'
  has_many :aliquots, class_name: 'Sequencescape::Api::V2::Aliquot'

  def latest_concentration
    latest_qc(key: 'concentration', units: 'ng/ul')
  end

  def latest_molarity
    latest_qc(key: 'molarity', units: 'nM')
  end

  def latest_qc(key:, units:)
    qc_results
      .to_a # Convert to array to resolve any api queries. Otherwise select fails to work.
      .select { |qc| qc.key.casecmp(key).zero? }
      .select { |qc| qc.units.casecmp(units).zero? }
      .max_by(&:created_at)
  end

  def all_latest_qc
    Array(qc_results).sort_by(&:id).index_by(&:key).values || []
  end
end
