# frozen_string_literal: true

module LabwareCreators
  # Pools one or more source tubes into a single tube.
  # Provides an inbox list on the left hand side of the page listing
  # available tubes (tubes of the correct type).
  class PooledTubesFromWholeTubes < Base
    class SubmissionFailure < StandardError; end

    include SupportParent::TubeOnly
    include LabwareCreators::CustomPage
    attr_reader :tube_transfer, :child, :barcodes

    self.page = 'pooled_tubes_from_whole_tubes'
    self.attributes += [{ barcodes: [] }]

    validate :parents_suitable

    def create_labware!
      # Create a single tube
      # TODO: This should link to multiple parents in production
      tc = api.tube_from_tube_creation.create!(
        user: user_uuid,
        parent: parent_uuid,
        child_purpose: purpose_uuid
      )

      @child = tc.child

      # Transfer EVERYTHING into it
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes
      )
    end

    def barcodes=(input)
      @barcodes = (input || []).map(&:strip).reject(&:blank?)
    end

    # TODO: This should probably be asynchronous
    def available_tubes
      @search_options = OngoingTube.new(purpose_names: [parent.purpose.name], include_used: false)
      @search_results = Sequencescape::Api::V2::Tube.find_all(@search_options.v2_search_parameters,
                                                              includes: 'purpose', paginate: @search_options.v2_pagination)
    end

    def parents
      @parents ||= Sequencescape::Api::V2::Tube.find_all({ barcode: barcodes }, includes: [])
    end

    def parents_suitable
      # Plate#barcode =~ ensures different 'flavours' of the same barcode still match.
      # Ie. EAN13 encoded versions will match the Code39 encoded versions.
      missing_barcodes = barcodes.reject { |scanned_bc| parents.any? { |p| p.barcode =~ scanned_bc } }
      errors.add(:barcodes, "could not be found: #{missing_barcodes}") unless missing_barcodes.empty?
    end

    private

    def transfer_request_attributes
      parents.map do |parent|
        { source_asset: parent.uuid, target_asset: @child.uuid }
      end
    end
  end
end
