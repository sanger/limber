# frozen_string_literal: true

module ApiUrlHelper
  def self.included(base)
    base.extend(V2Expectations)
    base.extend(V2Stubs)
  end

  # Expectations for the V2 API.
  # All methods here generate an expectation that the endpoint will be called with the correct arguments.
  # rubocop:todo Metrics/ModuleLength
  module V2Expectations
    def expect_posts(klass, args_list, return_values = [], method: :create!)
      # Expects the specified `method` for any class beginning with
      # 'Sequencescape::Api::V2::' to be called with given arguments, in sequence, and returns the given values.
      # If return_values is empty, it will return true.
      receiving_class = "Sequencescape::Api::V2::#{klass}".constantize
      args_list
        .zip(return_values)
        .each do |args, ret|
          ret ||= true
          expect(receiving_class).to receive(method).with(args).and_return(ret)
        end
    end

    def do_not_expect_posts(klass, args_list, return_values = [], method: :create!)
      # Expects the specified `method` for any class beginning with
      # 'Sequencescape::Api::V2::' to not be called with given arguments, in sequence.
      receiving_class = "Sequencescape::Api::V2::#{klass}".constantize
      args_list.zip(return_values).each { |_args, _| expect(receiving_class).not_to receive(method) }
    end

    def expect_custom_metadatum_collection_creation
      expect_posts('CustomMetadatumCollection', custom_metadatum_collections_attributes)
    end

    def expect_bulk_transfer_creation
      expect_posts('BulkTransfer', bulk_transfer_attributes)
    end

    def expect_order_creation
      expect_posts(
        'Order',
        orders_attributes.pluck(:attributes),
        orders_attributes.map { |attributes| double('Order', uuid: attributes[:uuid_out]) }
      )
    end

    def expect_plate_conversion_creation
      expect_posts(
        'PlateConversion',
        plate_conversions_attributes,
        plate_conversions_attributes.map do |e|
          new_plate = Plate.new(e[:target_uuid])
          double('plate_conversion_attributes',
                 target: double('plate_conversion_attributes_target', uuid: e[:target_uuid],
                                                                      to_model: new_plate))
        end
      )
    end

    def expect_plate_creation(child_plates = nil)
      child_plates ||= [child_plate] * plate_creations_attributes.size
      return_values = child_plates.map { |child_plate| double(child: child_plate) }
      expect_posts('PlateCreation', plate_creations_attributes, return_values)
    end

    def expect_pooled_plate_creation
      expect_posts(
        'PooledPlateCreation',
        pooled_plates_attributes,
        [double(child: child_plate)] * pooled_plates_attributes.size
      )
    end

    def expect_qc_file_creation
      expect_posts('QcFile', qc_files_attributes)
    end

    def expect_specific_tube_creation
      # Prepare the expected arguments and return values.
      arguments =
        specific_tubes_attributes.map do |attrs|
          {
            child_purpose_uuids: [attrs[:uuid]] * attrs[:child_tubes].size,
            parent_uuids: attrs[:parent_uuids],
            tube_attributes: attrs[:tube_attributes],
            user_uuid: user_uuid
          }
        end

      specific_tube_creations = specific_tubes_attributes.map { |attrs| double(children: attrs[:child_tubes]) }

      # Create the expectation.
      expect_posts('SpecificTubeCreation', arguments, specific_tube_creations)
    end

    def expect_state_change_creation
      expect_posts('StateChange', state_changes_attributes)
    end

    def expect_submission_creation
      expect_posts(
        'Submission',
        submissions_attributes.pluck(:attributes),
        submissions_attributes.map { |attributes| double('Submission', uuid: attributes[:uuid_out]) }
      )
    end

    def expect_tag_layout_creation
      expect_posts('TagLayout', tag_layouts_attributes)
    end

    def expect_transfer_creation
      expect_posts(
        'Transfer',
        transfers_attributes.pluck(:arguments),
        transfers_attributes.pluck(:response) # Missing responses become nil which will trigger a default value.
      )
    end

    def expect_transfer_request_collection_creation
      expect_posts('TransferRequestCollection', [{ transfer_requests_attributes:, user_uuid: }])
    end

    def expect_tube_from_tube_creation
      expect_posts(
        'TubeFromTubeCreation',
        tube_from_tubes_attributes,
        [double(child: child_tube)] * tube_from_tubes_attributes.size
      )
    end

    def expect_tube_from_plate_creation
      expect_posts(
        'TubeFromPlateCreation',
        tubes_from_plate_attributes,
        [instance_double(Sequencescape::Api::V2::TubeFromPlateCreation, child: child_tubes.first)]
      )
    end

    def expect_work_completion_creation
      expect_posts('WorkCompletion', work_completions_attributes)
    end

    def do_not_expect_work_completion_creation
      do_not_expect_posts('WorkCompletion', work_completions_attributes, [], method: :create!)
    end
  end
  # rubocop:enable Metrics/ModuleLength

  # Stubs for the V2 API.
  # None of the methods here generate an expectation that the endpoint will be called.
  # rubocop:todo Metrics/ModuleLength
  module V2Stubs
    def stub_patch(klass)
      # intercepts the 'update' and 'update!' method for any instance of the class beginning with
      # 'Sequencescape::Api::V2::' and returns true.
      receiving_class = "Sequencescape::Api::V2::#{klass}".constantize
      allow_any_instance_of(receiving_class).to receive(:update).and_return(true)
      allow_any_instance_of(receiving_class).to receive(:update!).and_return(true)
    end

    def stub_save(klass)
      # intercepts the 'save' method for any instance of the class beginning with
      # 'Sequencescape::Api::V2::' and returns true.
      receiving_class = "Sequencescape::Api::V2::#{klass}".constantize
      allow_any_instance_of(receiving_class).to receive(:save).and_return(true)
    end

    def stub_post(klass, return_value = nil, method: :create!)
      # intercepts the specified `method` for any class beginning with
      # 'Sequencescape::Api::V2::' and returns the given `return_value`, or else `true`.
      receiving_class = "Sequencescape::Api::V2::#{klass}".constantize
      return_value ||= true
      allow(receiving_class).to receive(method).and_return(return_value)
    end

    def stub_barcode_search(barcode, labware)
      labware_result = create :labware, type: labware.type, uuid: labware.uuid, id: labware.id
      allow(Sequencescape::Api::V2).to receive(:minimal_labware_by_barcode).with(barcode).and_return(labware_result)
    end

    def stub_find_by(klass, record, custom_includes: nil)
      # Set up find_by stubs for both barcode and uuid.
      [{ barcode: record.barcode.machine }, { uuid: record.uuid }].each do |query|
        query[:includes] = custom_includes if custom_includes
        allow(klass).to receive(:find_by).with(query).and_return(record)
      end
    end

    # Stubs a request for all barcode printers
    def stub_barcode_printers(printers)
      allow(Sequencescape::Api::V2::BarcodePrinter).to receive(:all).and_return(printers)
    end

    def stub_labware(labware)
      [{ barcode: labware.barcode.machine }, { uuid: labware.uuid }].each do |query|
        allow(Sequencescape::Api::V2::Labware).to receive(:find).with(query).and_return([labware])
      end
    end

    # rubocop:todo Metrics/AbcSize
    def stub_tube_rack(tube_rack, stub_search: true, custom_query: nil, custom_includes: nil)
      stub_barcode_search(tube_rack.barcode.machine, tube_rack) if stub_search

      if custom_query
        allow(Sequencescape::Api::V2).to receive(custom_query.first).with(*custom_query.last).and_return(tube_rack)
      elsif custom_includes
        allow(Sequencescape::Api::V2).to receive(:tube_rack_with_custom_includes).with(
          custom_includes,
          nil,
          { uuid: tube_rack.uuid }
        ).and_return(tube_rack)
      else
        allow(Sequencescape::Api::V2).to receive(:tube_rack_for_presenter).with(uuid: tube_rack.uuid).and_return(
          tube_rack
        )
      end

      arguments = [{ uuid: tube_rack.uuid }]
      allow(Sequencescape::Api::V2::TubeRack).to receive(:find).with(*arguments).and_return([tube_rack])
    end
    # rubocop:enable Metrics/AbcSize

    def stub_tube_rack_purpose(tube_rack_purpose)
      arguments = [{ name: tube_rack_purpose[:name] }]
      allow(Sequencescape::Api::V2::TubeRackPurpose).to receive(:find).with(*arguments).and_return([tube_rack_purpose])
    end

    def stub_racked_tube(racked_tube)
      arguments = [{ tube_rack: racked_tube.tube_rack.id, tube: racked_tube.tube.id }]
      allow(Sequencescape::Api::V2::RackedTube).to receive(:find).with(*arguments).and_return(racked_tube)
    end

    # Builds the basic v2 plate finding query.
    def stub_plate(plate, stub_search: true, custom_query: nil, custom_includes: nil) # rubocop:todo Metrics/AbcSize
      stub_barcode_search(plate.barcode.machine, plate) if stub_search

      if custom_query
        allow(Sequencescape::Api::V2).to receive(custom_query.first).with(*custom_query.last).and_return(plate)
      elsif custom_includes
        allow(Sequencescape::Api::V2).to receive(:plate_with_custom_includes).with(
          custom_includes,
          { uuid: plate.uuid }
        ).and_return(plate)
      else
        allow(Sequencescape::Api::V2).to receive(:plate_for_presenter).with(uuid: plate.uuid).and_return(plate)
      end

      stub_find_by(Sequencescape::Api::V2::Plate, plate, custom_includes:)
      stub_labware(plate)
    end

    def stub_polymetadata(polymetadata, metadatable_id)
      arguments = [{ key: polymetadata.key, metadatable_id: metadatable_id }]
      allow(Sequencescape::Api::V2::PolyMetadatum).to receive(:find).with(*arguments).and_return([polymetadata])
    end

    def stub_project(project)
      arguments = [{ name: project.name }]
      allow(Sequencescape::Api::V2::Project).to receive(:find).with(*arguments).and_return([project])
    end

    def stub_qc_file(qc_file)
      arguments = [{ uuid: qc_file.uuid }]
      allow(Sequencescape::Api::V2::QcFile).to receive(:find).with(*arguments).and_return([qc_file])
    end

    def stub_qcable(qcable)
      arguments = [{ barcode: qcable.labware.barcode.machine }]
      query_builder = double('query_builder')

      allow(Sequencescape::Api::V2::Qcable).to receive(:includes).and_return(query_builder)
      allow(query_builder).to receive(:find).with(*arguments).and_return([qcable])
    end

    def stub_study(study)
      arguments = [{ name: study.name }]
      allow(Sequencescape::Api::V2::Study).to receive(:find).with(*arguments).and_return([study])
    end

    def stub_tag_layout_templates(templates)
      query = double('tag_layout_template_query')
      allow(Sequencescape::Api::V2::TagLayoutTemplate).to receive(:paginate).and_return(query)
      allow(Sequencescape::Api::V2).to receive(:merge_page_results).with(query).and_return(templates)
    end

    # Builds the basic v2 tube finding query.
    def stub_tube(tube, stub_search: true, custom_query: nil, custom_includes: nil)
      stub_barcode_search(tube.barcode.machine, tube) if stub_search

      if custom_query
        allow(Sequencescape::Api::V2).to receive(custom_query.first).with(*custom_query.last).and_return(tube)
      end

      stub_find_by(Sequencescape::Api::V2::Tube, tube, custom_includes:)
      stub_labware(tube)
    end

    def stub_user(user, swipecard = nil)
      # Find by UUID
      uuid_args = [{ uuid: user.uuid }]
      allow(Sequencescape::Api::V2::User).to receive(:find).with(*uuid_args).and_return([user])

      return unless swipecard

      # Find by swipecard
      swipecard_args = [{ user_code: swipecard }]
      allow(Sequencescape::Api::V2::User).to receive(:find).with(*swipecard_args).and_return([user])
    end

    def stub_pooled_plate_creation
      # Stubs the creation of a pooled plate by returning a double with a child attribute.
      pooled_plate_creation = double('pooled_plate_creation')
      allow(pooled_plate_creation).to receive(:child).and_return(child_plate)

      stub_post('PooledPlateCreation', pooled_plate_creation)
    end
  end
  # rubocop:enable Metrics/ModuleLength
end

RSpec.configure do |config|
  config.include ApiUrlHelper
  config.include ApiUrlHelper::V2Expectations
  config.include ApiUrlHelper::V2Stubs
end
