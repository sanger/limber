# frozen_string_literal: true

module LabwareCreators
  # Pools an entire plate into a single tube. Useful for MiSeqQC
  class PooledTubesFromWholeTubes < Base
    class SubmissionFailure < StandardError; end

    include SupportParent::TubeOnly
    include LabwareCreators::CustomPage
    attr_reader :tube_transfer, :child

    self.page = 'pooled_tubes_from_whole_tubes'
    self.attributes = %i[api purpose_uuid parent_uuid user_uuid barcodes]

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

      generate_submissions_for_child
    end

    def barcodes=(input)
      @barcodes = (input || []).map(&:strip).reject(&:blank?)
    end

    # TODO: This should probably be asynchronous
    def available_tubes
      @ongoing_plate = OngoingTube.new(tube_purposes: [parent.purpose.uuid], include_used: false, states: ['passed'])
      @search_results = tube_search.all(
        Limber::Tube,
        @ongoing_plate.search_parameters
      )
    end

    def parents
      @parents ||= api.search.find(Settings.searches['Find assets by barcode']).all(Limber::BarcodedAsset, barcode: barcodes)
    end

    def parents_suitable
      missing_barcodes = barcodes - parents.map { |p| p.barcode.ean13 }
      errors.add(:barcodes, "could not be found: #{missing_barcodes}") unless missing_barcodes.empty?
    end

    private

    def generate_submissions_for_child
      order = submission_template.orders.create!(
        assets: [@child.uuid],
        request_options: request_options,
        user: user_uuid
      )

      submission = api.submission.create!(
        orders: [order.uuid],
        user: user_uuid
      )

      submission.submit!
    rescue Sequencescape::Api::ConnectionFactory::Actions::ServerError => exception
      raise SubmissionFailure, ('Submission Failed. ' + /.+\[([^\]]+)\]/.match(exception.message)[1])
    rescue Sequencescape::Api::ResourceInvalid => exception
      raise SubmissionFailure, ('Submission Failed. ' + exception.resource.errors.full_messages.join('; '))
    end

    def transfer_request_attributes
      parents.each_with_object([]) do |parent, transfer_requests|
        transfer_requests << { source_asset: parent.uuid, target_asset: @child.uuid }
      end
    end

    def submission_template
      api.order_template.find(purpose_config.submission.template_uuid)
    end

    def request_options
      purpose_config.submission.options
    end

    def tube_search
      api.search.find(Settings.searches.fetch('Find tubes'))
    end
  end
end
