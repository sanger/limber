# frozen_string_literal: true

module LabwareCreators
  # Includes the addition of PhiX, a specific type of control sample.
  # User scans SpikedBuffer tube containing PhiX into an interstitial page, on tube creation.
  # SpikedBuffer tube is recorded as a parent of the newly created tube(s).
  class PooledTubesBySubmissionWithPhiX < PooledTubesBySubmission
    include LabwareCreators::CustomPage

    validate :tube_must_be_spiked_buffer

    self.page = 'tube_creation/phix_addition'
    self.attributes += [:spikedbuffer_tube_barcode]

    attr_accessor :spikedbuffer_tube_barcode

    def create_child_stock_tubes
      Sequencescape::Api::V2::SpecificTubeCreation
        .create!(
          child_purpose_uuids: [purpose_uuid] * pool_uuids.length,
          parent_uuids: parents,
          tube_attributes: tube_attributes,
          user_uuid: user_uuid
        )
        .children
        .index_by(&:name)
    end

    def parents
      parents = [parent_uuid]
      parents << scanned_tube.uuid if spikedbuffer_tube_barcode.present?
      parents
    end

    # It is valid to not provide a spikedbuffer_tube_barcode, but if provided out it must make sense
    def tube_must_be_spiked_buffer
      return if spikedbuffer_tube_barcode.blank?

      errors.add(:base, "A tube with that barcode couldn't be found.") if scanned_tube.blank?
      # TODO: add validation to check tube is SpikedBuffer (requires change to SS V2 API)
    end

    # Only call this method if the spikedbuffer_tube_barcode is present
    def scanned_tube
      search_params = { barcode: spikedbuffer_tube_barcode }
      if defined?(@scanned_tube)
        @scanned_tube
      else
        @scanned_tube = Sequencescape::Api::V2::Tube.find_by(search_params)
      end
    end
  end
end
