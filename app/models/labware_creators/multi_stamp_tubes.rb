# frozen_string_literal: true

module LabwareCreators
  class MultiStampTubes < Base # rubocop:todo Style/Documentation
    include LabwareCreators::CustomPage
    include SupportParent::TubeOnly

    attr_accessor :transfers, :parents

    class_attribute :request_filter, :transfers_layout, :transfers_creator, :target_rows, :target_columns, :source_tubes

    self.page = 'multi_stamp_tubes'
    self.aliquot_partial = 'standard_aliquot'
    self.request_filter = 'null'
    self.transfers_layout = 'null'
    self.transfers_creator = 'multi-stamp-tubes'
    self.attributes += [
      {
        transfers: [
          [:source_tube, :source_asset, :outer_request, :pool_index, { new_target: :location }]
        ]
      }
    ]
    self.target_rows = 8
    self.target_columns = 12
    self.source_tubes = 96

    validates :transfers, presence: true

    def allow_tube_duplicates?
      params.fetch('allow_tube_duplicates', false)
    end

    private

    def create_labware!
      plate_creation = api.pooled_plate_creation.create!(
        parents: parent_uuids,
        child_purpose: purpose_uuid,
        user: user_uuid
      )

      @child = plate_creation.child
      child_v2 = Sequencescape::Api::V2.plate_with_wells(@child.uuid)

      transfer_material_from_parent!(child_v2)

      create_submission_from_child_plate(child_v2)

      yield(@child) if block_given?
      true
    end

    # Returns a list of parent tube uuids extracted from the transfers
    def parent_uuids
      transfers.pluck(:source_tube).uniq
    end

    def transfer_material_from_parent!(child_plate)
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes(child_plate)
      )
    end

    def transfer_request_attributes(child_plate)
      transfers.map do |transfer|
        request_hash(transfer, child_plate)
      end
    end

    def request_hash(transfer, child_plate)
      {
        'source_asset' => transfer[:source_asset],
        'target_asset' => child_plate.wells.detect do |child_well|
                            child_well.location == transfer.dig(:new_target, :location)
                          end&.uuid
      }
    end

    def create_submission_from_child_plate(child_plate)
      submission_options_from_config = purpose_config.submission_options
      # if there's more than one appropriate submission, we can't know which one to choose,
      # so don't create one.
      return unless submission_options_from_config.count == 1

      # otherwise, create a submission with params specified in the config
      configured_params = submission_options_from_config.values.first

      sequencescape_submission_parameters = {
        template_name: configured_params[:template_name],
        labware_barcode: child_plate.human_barcode,
        request_options: configured_params[:request_options],
        asset_groups: [{ assets: child_plate.wells.pluck(:uuid), autodetect_studies_projects: true }],
        api: api,
        user: user_uuid
      }

      ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
      ss.save # TODO: check if true, handle if not
    end
  end
end
