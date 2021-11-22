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

    PLATE_INCLUDES = 'wells,wells.aliquots,wells.aliquots.study'

    def allow_tube_duplicates?
      params.fetch('allow_tube_duplicates', false)
    end

    private

    def create_labware!
      create_submission_from_parent_tubes

      # TODO: Hack - change this to poll for status or something
      puts '*** Waiting for it to build ***'
      sleep(10)

      plate_creation = api.pooled_plate_creation.create!(
        parents: parent_uuids,
        child_purpose: purpose_uuid,
        user: user_uuid
      )

      @child = plate_creation.child
      child_v2 = Sequencescape::Api::V2.plate_with_wells(@child.uuid)

      transfer_material_from_parent!(child_v2)

      # re-fetch plate with additional includes to get aliquot information and study
      child_v2 = Sequencescape::Api::V2.plate_with_custom_includes(PLATE_INCLUDES, uuid: @child.uuid) # reload to get the aliquots
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

    def source_tube_outer_request_uuid(tube)
      # Assumptions: the requests we want will still be in state pending, and there will only be one
      # Alternatively, if we know what request type we are expecting, we could look for that type
      pending_reqs = tube.receptacle.requests_as_source.reject { |req| req.state == 'passed' }
      pending_reqs.first.uuid
    end

    def request_hash(transfer, child_plate)
      tube = Sequencescape::Api::V2::Tube.find_by(uuid: transfer[:source_tube])

      {
        'source_asset' => transfer[:source_asset],
        'target_asset' => child_plate.wells.detect do |child_well|
                            child_well.location == transfer.dig(:new_target, :location)
                          end&.uuid,
        'outer_request' => source_tube_outer_request_uuid(tube)
      }
    end

    def submission_options_from_config
      @submission_options_from_config ||= purpose_config.submission_options
    end

    def occupied_wells(wells)
      wells.reject(&:empty?)
    end

    def asset_groups(child_plate)
      # split the wells by study id e.g. { '1': [<well1>, <well3>, <well4>], '2': [{<well2>, <well5>}]}
      study_wells = occupied_wells(child_plate.wells).group_by { |well| well.aliquots.first.study.id }

      # then build asset groups by study in a hash
      study_wells.transform_values do |wells|
        {
          assets: wells.pluck(:uuid),
          autodetect_studies_projects: true
        }
      end
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
        request_options: configured_params[:request_options],
        asset_groups: asset_groups(child_plate),
        api: api,
        user: user_uuid
      }

      ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
      ss.save # TODO: check if true, handle if not
    end
  end
end
