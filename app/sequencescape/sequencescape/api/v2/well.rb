# frozen_string_literal: true

class Sequencescape::Api::V2::Well < Sequencescape::Api::V2::Base
  belongs_to :plate
  has_many :qc_results

  def latest_concentration
    qc_results.select { |qc| qc.key == 'concentration' }
              .sort_by { |qc| qc.created_at }
              .last
  end

  def passed?
    state == 'passed'
  end
end
