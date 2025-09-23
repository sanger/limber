# frozen_string_literal: true

module LabwareCreators
  # Pools one or more source tubes into a single tube.
  # Provides an inbox list on the left hand side of the page listing
  # available tubes (tubes of the correct type).
  class PooledTubesFromWholeTubes < Base
    class SubmissionFailure < StandardError
    end

    include CreatableFrom::TubeOnly
    include LabwareCreators::CustomPage

    attr_reader :tube_transfer, :child, :barcodes

    self.page = 'pooled_tubes_from_whole_tubes'
    self.attributes += [{ barcodes: [] }]

    validate :parents_suitable

    def create_labware!
      # Create a single tube
      # TODO: This should link to multiple parents in production
      @child =
        Sequencescape::Api::V2::TubeFromTubeCreation.create!(
          child_purpose_uuid: purpose_uuid,
          parent_uuid: parent_uuid,
          user_uuid: user_uuid
        ).child

      # Transfer EVERYTHING into it
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes,
        user_uuid: user_uuid
      )
    end

    def barcodes=(input)
      @barcodes = (input || []).map(&:strip).compact_blank
    end

    # TODO: This should probably be asynchronous
    def available_tubes
      @search_options = OngoingTube.new(purpose_names: [parent.purpose.name], include_used: false)
      @search_results =
        Sequencescape::Api::V2::Tube.find_all(
          @search_options.search_parameters,
          includes: 'purpose',
          paginate: @search_options.pagination
        )
    end

    def parents
      @parents ||= Sequencescape::Api::V2::Tube.find_all({ barcode: barcodes }, includes: [])
    end

    def parents_suitable
      # Plate#barcode =~ ensures different 'flavours' of the same barcode still match.
      # Ie. EAN13 encoded versions will match the Code39 encoded versions.
      missing_barcodes = barcodes.reject { |scanned_bc| parents.any? { |p| p.barcode =~ scanned_bc } }
      return if missing_barcodes.empty?

      errors.add(:barcodes, "could not be found: #{missing_barcodes}")
    end

    def number_of_parent_labwares
      # default to 4 if value not found in config
      purpose_config.fetch(:number_of_parent_labwares, 4)
    end

    def redirection_target
      Tube.new(@child.uuid)
    end

    private

    def transfer_request_attributes
      parents.map { |parent| { source_asset: parent.uuid, target_asset: @child.uuid } }
    end
  end
end
