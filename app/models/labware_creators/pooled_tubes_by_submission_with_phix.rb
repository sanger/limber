# frozen_string_literal: true

module LabwareCreators
  # Includes the addition of PhiX, a specific type of control sample.
  # User scans SpikedBuffer tube containining PhiX into an interstitial page, on tube creation.
  # SpikedBuffer tube is recorded as a parent of the newly created tube(s).
  class PooledTubesBySubmissionWithPhiX < PooledTubesBySubmission
    include LabwareCreators::CustomPage

    self.page = 'phix_addition'
    self.attributes += [
      :spikedbuffer_tube_barcode
    ]

    attr_accessor :spikedbuffer_tube_barcode

    def create_child_stock_tubes
      spiked_buffer_tube = Sequencescape::Api::V2::Tube.find_by(barcode: spikedbuffer_tube_barcode)

      tubes = api.specific_tube_creation.create!(
        user: user_uuid,
        parents: [parent_uuid, spiked_buffer_tube.uuid],
        child_purposes: [purpose_uuid] * pool_uuids.length,
        tube_attributes: tube_attributes
      ).children.index_by(&:name)

      tubes
    end
  end
end
