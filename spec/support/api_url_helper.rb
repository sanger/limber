# frozen_string_literal: true

module ApiUrlHelper
  API_ROOT = 'http://example.com:3000'

  def self.included(base)
    base.extend(V1Helpers)
    base.extend(V2Helpers)
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

  module V2Helpers
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

    def stub_barcode_search(barcode, labware)
      labware_result = create :labware, type: labware.type, uuid: labware.uuid, id: labware.id
      allow(Sequencescape::Api::V2).to receive(:minimal_labware_by_barcode).with(barcode).and_return(labware_result)
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

      # Find by Barcode
      barcode_args = { barcode: plate.barcode.machine }
      barcode_args[:includes] = custom_includes if custom_includes
      allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(*[barcode_args]).and_return(plate)

      # Find by UUID
      uuid_args = { uuid: plate.uuid }
      uuid_args[:includes] = custom_includes if custom_includes
      allow(Sequencescape::Api::V2::Plate).to receive(:find_by).with(*[uuid_args]).and_return(plate)

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

      # Find by Barcode
      barcode_args = { barcode: tube.barcode.machine }
      barcode_args[:includes] = custom_includes if custom_includes
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(*[barcode_args]).and_return(tube)

      # Find by UUID
      uuid_args = { uuid: tube.uuid }
      uuid_args[:includes] = custom_includes if custom_includes
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(*[uuid_args]).and_return(tube)

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
  end
end

RSpec.configure do |config|
  config.include ApiUrlHelper
  config.include ApiUrlHelper::V1Helpers
  config.include ApiUrlHelper::V2Helpers
end
