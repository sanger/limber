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
      submission_created = create_submission_from_parent_tubes
      unless submission_created
        errors.add(:base, "Failed to create submission")
        return
      end

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

      yield(@child) if block_given?
      true
    end

    # Returns a list of parent tube uuids extracted from the transfers
    def parent_uuids
      transfers.pluck(:source_tube).uniq
    end

    def parent_tubes
      Sequencescape::Api::V2::Tube.find_all({ uuid: parent_uuids }, includes: 'receptacle,aliquots,aliquots.study')
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

    def asset_groups
      # split the receptacles by study id e.g. { '1': [<receptacle1>, <receptacle3>, <receptacle4>], '2': [{<receptacle2>, <receptacle5>}]}
      tubes_by_study = parent_tubes.group_by { |tube| tube.aliquots.first.study.id }

      # then build asset groups by study in a hash
      tubes_by_study.transform_values do |tubes|
        {
          assets: tubes.map{ |tube| tube.receptacle.uuid },
          autodetect_studies_projects: true
        }
      end
    end

    def create_submission_from_parent_tubes
      submission_options_from_config = purpose_config.submission_options

      # if there's more than one appropriate submission, we can't know which one to choose,
      # so don't create one.
      return unless submission_options_from_config.count == 1

      # otherwise, create a submission with params specified in the config
      configured_params = submission_options_from_config.values.first

      sequencescape_submission_parameters = {
        template_name: configured_params[:template_name],
        request_options: configured_params[:request_options],
        asset_groups: asset_groups,
        api: api,
        user: user_uuid
      }

      ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
      submission_created = ss.save
      binding.pry
      if submission_created
        return true
      else
        errors.add(:base, ss.errors.full_messages)
        return false
      end
    end
  end
end
