# frozen_string_literal: true

# A LotType from sequencescape via the V2 API
class Sequencescape::Api::V2::LotType < Sequencescape::Api::V2::Base
  has_one :target_purpose, class_name: 'Sequencescape::Api::V2::Purpose'
end
