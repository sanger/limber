# frozen_string_literal: true

class Sequencescape::Api::V2::Plate < Sequencescape::Api::V2::Base
  has_many :wells
  has_many :samples
end
