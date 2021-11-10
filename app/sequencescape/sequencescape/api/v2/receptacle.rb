# frozen_string_literal: true

class Sequencescape::Api::V2::Receptacle < Sequencescape::Api::V2::Base
  has_many :qc_results, class_name: 'Sequencescape::Api::V2::QcResult'
end
