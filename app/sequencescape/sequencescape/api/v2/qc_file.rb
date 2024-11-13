# frozen_string_literal: true

# A QcFile from sequencescape via the V2 API
class Sequencescape::Api::V2::QcFile < Sequencescape::Api::V2::Base
  has_one :labware

  # The endpoint requires that the labware relationship is of a Labware type.
  # Since we create for plates and tubes, not the more generic labware type, we will declare the relationship manually.
  def self.create_for_labware!(labware:, contents:, filename:)
    relationships = { labware: { data: { id: labware.id, type: 'labware' } } }
    create!(contents:, filename:, relationships:)
  end
end
