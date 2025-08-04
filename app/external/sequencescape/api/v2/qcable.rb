# frozen_string_literal: true

# A Qcable from sequencescape via the V2 API
class Sequencescape::Api::V2::Qcable < Sequencescape::Api::V2::Base
  has_one :labware
  has_one :lot
end
