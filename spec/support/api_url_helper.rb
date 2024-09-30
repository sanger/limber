# frozen_string_literal: true

module ApiUrlHelper
  API_ROOT = 'http://example.com:3000'

  def self.included(base)
    base.extend(V1Helpers)
    base.extend(V2Expectations)
    base.extend(V2Stubs)
  end

  module V1Helpers
    def api_root
      API_ROOT
    end

    def api_url_for(*components)
      model = components.shift
      uuid = model.is_a?(String) ? model : model.uuid
      [api_root, uuid, *components].join('/')
    end

    # Generate an API stub for a get request.
    # eg. stub_api_get(plate, 'children', body: json(:plate_collection))
    # stub_api_get(plate_uuid, body: json(:plate))
    # @param [Api::Resource,*String] components one or more components that form
    #                                the url. Models are converted to their uuid.
    # @param [String] body: named_parameter reflecting the expected response JSON
    # @param [Int] status: the response status, defaults to 200
    # @return mocked_request
    def stub_api_get(*components, status: 200, body: '{}')
      stub_request(:get, api_url_for(*components))
        .with(headers: { 'Accept' => 'application/json' })
        .to_return(status: status, body: body, headers: { 'content-type' => 'application/json' })
    end

    # Generate an API stub for a post request.
    # eg. stub_api_get(plate, 'children', body: json(:plate_collection))
    # stub_api_post('transfer-to-wells-by-submission-uuid',
    #               payload: { transfer: {
    #                 targets: { 'pool-1-uuid' => 'tube-0', 'pool-2-uuid' => 'tube-1' },
    #                 source: parent_uuid,
    #                 user: user_uuid
    #               }},
    #               body: json(:transfer))
    # rubocop:todo Layout/LineLength
    # @param [Api::Resource,*String] components one or more components that form the url. Models are converted to their uuid.
    # rubocop:enable Layout/LineLength
    # @param [String] body: named_parameter reflecting the expected response JSON
    # @param [Hash] payload: the payload of the post request. Hash strongly recommended over raw json
    # @param [Int] status: the response status, defaults to 201
    # @return mocked_request
    def stub_api_post(*components, status: 201, body: '{}', payload: {})
      stub_api_modify(*components, status: status, body: body, payload: payload)
    end

    def stub_api_modify(*components, body:, payload:, action: :post, status: 201)
      Array(body)
        .reduce(
          stub_request(action, api_url_for(*components)).with(
            headers: {
              'Accept' => 'application/json',
              'content-type' => 'application/json'
            },
            body: payload
          )
        ) do |request, response|
          request.to_return(status: status, body: response, headers: { 'content-type' => 'application/json' })
        end
    end

    def stub_api_put(*components, body:, payload:)
      stub_api_modify(*components, action: :put, status: 200, body: body, payload: payload)
    end
  end

  # Expectations for the V2 API.
  # All methods here generate an expectation that the endpoint will be called with the correct arguments.
  module V2Expectations
    def expect_api_v2_posts(klass, args_list, return_values = [], method: :create!)
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

    def expect_custom_metadatum_collection_creation
      expect_api_v2_posts('CustomMetadatumCollection', custom_metadatum_collections_attributes)
    end

    def expect_pooled_plate_creation
      expect_api_v2_posts(
        'PooledPlateCreation',
        pooled_plates_attributes,
        [double(child: child_plate)] * pooled_plates_attributes.size
      )
    end

    def expect_specific_tube_creation
      # Prepare the expected arguments and return values.
      arguments =
        specific_tubes_attributes.map do |attrs|
          {
            child_purpose_uuids: [attrs[:uuid]] * attrs[:child_tubes].size,
            parent_uuids: [parent_uuid],
            tube_attributes: attrs[:tube_attributes],
            user_uuid: user_uuid
          }
        end

      specific_tube_creations = specific_tubes_attributes.map { |attrs| double(children: attrs[:child_tubes]) }

      # Create the expectation.
      expect_api_v2_posts('SpecificTubeCreation', arguments, specific_tube_creations)
    end

    def expect_state_change_creation
      expect_api_v2_posts('StateChange', state_changes_attributes)
    end

    def expect_transfer_creation
      expect_api_v2_posts(
        'Transfer',
        transfers_attributes.map { |attrs| attrs[:arguments] },
        transfers_attributes.map { |attrs| attrs.fetch(:response, true) }
      )
    end

    def expect_transfer_request_collection_creation
      expect_api_v2_posts(
        'TransferRequestCollection',
        [{ transfer_requests_attributes: transfer_requests_attributes, user_uuid: user_uuid }]
      )
    end
  end

  # Stubs for the V2 API.
  # None of the methods here generate an expectation that the endpoint will be called.
  module V2Stubs
    def stub_api_v2_patch(klass)
      # intercepts the 'update' and 'update!' method for any instance of the class beginning with
      # 'Sequencescape::Api::V2::' and returns true.
      receiving_class = "Sequencescape::Api::V2::#{klass}".constantize
      allow_any_instance_of(receiving_class).to receive(:update).and_return(true)
      allow_any_instance_of(receiving_class).to receive(:update!).and_return(true)
    end

    def stub_api_v2_save(klass)
      # intercepts the 'save' method for any instance of the class beginning with
      # 'Sequencescape::Api::V2::' and returns true.
      receiving_class = "Sequencescape::Api::V2::#{klass}".constantize
      allow_any_instance_of(receiving_class).to receive(:save).and_return(true)
    end

    def stub_api_v2_post(klass, return_value = nil, method: :create!)
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
      # Find by Barcode
      barcode_args = { barcode: record.barcode.machine }
      barcode_args[:includes] = custom_includes if custom_includes
      allow(klass).to receive(:find_by).with(barcode_args).and_return(record)

      # Find by UUID
      uuid_args = { uuid: record.uuid }
      uuid_args[:includes] = custom_includes if custom_includes
      allow(klass).to receive(:find_by).with(uuid_args).and_return(record)
    end

    # Stubs a request for all barcode printers
    def stub_v2_barcode_printers(printers)
      allow(Sequencescape::Api::V2::BarcodePrinter).to receive(:all).and_return(printers)
    end

    def stub_v2_labware(labware)
      arguments = [{ barcode: labware.barcode.machine }]
      allow(Sequencescape::Api::V2::Labware).to receive(:find).with(*arguments).and_return([labware])
    end

    # Builds the basic v2 plate finding query.
    def stub_v2_plate(plate, stub_search: true, custom_query: nil, custom_includes: nil) # rubocop:todo Metrics/AbcSize
      stub_barcode_search(plate.barcode.machine, plate) if stub_search

      if custom_query
        allow(Sequencescape::Api::V2).to receive(custom_query.first).with(*custom_query.last).and_return(plate)
      elsif custom_includes
        allow(Sequencescape::Api::V2).to receive(:plate_with_custom_includes)
          .with(custom_includes, { uuid: plate.uuid })
          .and_return(plate)
      else
        allow(Sequencescape::Api::V2).to receive(:plate_for_presenter).with(uuid: plate.uuid).and_return(plate)
      end

      stub_find_by(Sequencescape::Api::V2::Plate, plate, custom_includes: custom_includes)
      stub_v2_labware(plate)
    end

    def stub_v2_polymetadata(polymetadata, metadatable_id)
      arguments = [{ key: polymetadata.key, metadatable_id: metadatable_id }]
      allow(Sequencescape::Api::V2::PolyMetadatum).to receive(:find).with(*arguments).and_return([polymetadata])
    end

    def stub_v2_project(project)
      arguments = [{ name: project.name }]
      allow(Sequencescape::Api::V2::Project).to receive(:find).with(*arguments).and_return([project])
    end

    def stub_v2_study(study)
      arguments = [{ name: study.name }]
      allow(Sequencescape::Api::V2::Study).to receive(:find).with(*arguments).and_return([study])
    end

    def stub_v2_tag_layout_templates(templates)
      query = double('tag_layout_template_query')
      allow(Sequencescape::Api::V2::TagLayoutTemplate).to receive(:paginate).and_return(query)
      allow(Sequencescape::Api::V2).to receive(:merge_page_results).with(query).and_return(templates)
    end

    # Builds the basic v2 tube finding query.
    def stub_v2_tube(tube, stub_search: true, custom_includes: false)
      stub_barcode_search(tube.barcode.machine, tube) if stub_search

      stub_find_by(Sequencescape::Api::V2::Tube, tube, custom_includes: custom_includes)
      stub_v2_labware(tube)
    end

    def stub_v2_user(user, swipecard = nil)
      # Find by UUID
      uuid_args = [{ uuid: user.uuid }]
      allow(Sequencescape::Api::V2::User).to receive(:find).with(*uuid_args).and_return([user])

      return unless swipecard

      # Find by swipecard
      swipecard_args = [{ user_code: swipecard }]
      allow(Sequencescape::Api::V2::User).to receive(:find).with(*swipecard_args).and_return([user])
    end

    def stub_v2_pooled_plate_creation
      # Stubs the creation of a pooled plate by returning a double with a child attribute.
      pooled_plate_creation = double
      allow(pooled_plate_creation).to receive(:child).and_return(child_plate)

      stub_api_v2_post('PooledPlateCreation', pooled_plate_creation)
    end
  end
end

RSpec.configure do |config|
  config.include ApiUrlHelper
  config.include ApiUrlHelper::V1Helpers
  config.include ApiUrlHelper::V2Expectations
  config.include ApiUrlHelper::V2Stubs
end
