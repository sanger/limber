# frozen_string_literal: true

module LabwareCreators
  # Pools an entire plate into a single tube. Useful for MiSeqQC
  class PooledTubesFromWholeTubes < Base
    class SubmissionFailure < StandardError; end

    include SupportParent::TubeOnly
    include LabwareCreators::CustomPage
    attr_reader :tube_transfer, :child, :barcodes

    self.page = 'pooled_tubes_from_whole_tubes'
    self.attributes += [{ barcodes: [] }]
    self.default_transfer_template_name = 'Whole plate to tube'

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
      @search_options = OngoingTube.new(purposes: [parent.purpose.uuid], include_used: false, states: ['passed'])
      @search_results = tube_search.all(
        Limber::Tube,
        @search_options.search_parameters
      )
    end

    def parents
      @parents ||= api.search.find(Settings.searches['Find assets by barcode']).all(Limber::BarcodedAsset,
                                                                                    barcode: barcodes)
    end

    def parents_suitable
      missing_barcodes = barcodes - parents.map { |p| p.barcode.ean13 }
      errors.add(:barcodes, "could not be found: #{missing_barcodes}") unless missing_barcodes.empty?
    end

    private

    def transfer_request_attributes
      parents.each_with_object([]) do |parent, transfer_requests|
        transfer_requests << { source_asset: parent.uuid, target_asset: @child.uuid }
      end
    end

    def tube_search
      api.search.find(Settings.searches.fetch('Find tubes'))
    end
  end
end
