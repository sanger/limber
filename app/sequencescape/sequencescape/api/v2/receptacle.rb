# frozen_string_literal: true

class Sequencescape::Api::V2::Receptacle < Sequencescape::Api::V2::Base
  has_many :requests_as_source, class_name: 'Sequencescape::Api::V2::Request'
end
