# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # A basic API V2 request. The factories inheriting from this
  # are probably more useful.
  factory :request, class: Sequencescape::Api::V2::Request, traits: [:uuid] do
    transient do
      pcr_cycles { 10 }
      sequence(:submission_id) { |i| i }
      sequence(:order_id) { |i| i }
      # Specifies that submission information should be included in the model
      # as though it had been requested via the API.
      include_submissions { false }
      library_type { 'Standard' }
    end

    initialize_with do
      Sequencescape::Api::V2::Request.load(attributes)
    end

    skip_create
    sequence(:id, &:to_s)
    role { 'WGS' }
    priority { 0 }
    state { 'pending' }
    options do
      {
        'pcr_cycles' => pcr_cycles,
        'fragment_size_required_from' => 100,
        'fragment_size_required_to' => 200,
        'library_type' => library_type
      }
    end
    request_type { create :request_type }
    primer_panel { nil }
    pre_capture_pool { nil }
    uuid
    submission do
      create :v2_submission, id: submission_id.to_s, uuid: "pool-#{submission_id + 1}-uuid" if include_submissions
    end

    after(:build) do |request, evaluator|
      RSpec::Mocks.allow_message(request, :submission).and_return(evaluator.submission)
      request.relationships.submission = {
        'links' => {
          'self' => "http://localhost:3000/api/v2/requests/#{request.id}/relationships/submission",
          'related' => "http://localhost:3000/api/v2/requests/#{request.id}/submission"
        },
        'data' => { 'type' => 'submissions', 'id' => evaluator.submission_id.to_s }
      }
      request.relationships.order = {
        'links' => {
          'self' => "http://localhost:3000/api/v2/requests/#{request.id}/relationships/order",
          'related' => "http://localhost:3000/api/v2/requests/#{request.id}/order"
        },
        'data' => { 'type' => 'orders', 'id' => evaluator.order_id.to_s }
      }
    end

    # Basic library creation request, such as wgs
    factory :library_request do
      request_type { create :library_request_type }

      # Library request with primer panel information
      factory :gbs_library_request do
        primer_panel
      end

      # Library request with bait library information
      factory :isc_library_request do
        pre_capture_pool
      end
    end

    # Multiplexing request, representing the pooling steps at the end of most
    # pipelines.
    factory :mx_request do
      request_type { create :mx_request_type }
    end

    # Aggregation request, representing the transfer of many plates onto
    # one at the beginning of the process
    factory :aggregation_request do
      request_type { create :aggregation_request_type }
    end
  end

  factory :primer_panel, class: Sequencescape::Api::V2::PrimerPanel do
    skip_create

    name { 'example panel' }
    programs do
      {
        'pcr 1' => { 'name' => 'example program', 'duration' => 45 },
        'pcr 2' => { 'name' => 'other program', 'duration' => 20 }
      }
    end
  end

  # V2 pre capture pool. Essentially primarily about grouping requests together
  factory :pre_capture_pool, class: Sequencescape::Api::V2::PreCapturePool do
    skip_create
    id { 1 }
    uuid { 'pre-capture-pool' }
  end

  # Basic V2 request type
  factory :request_type, class: Sequencescape::Api::V2::RequestType do
    skip_create
    name { 'Request Type' }
    key { 'request_type' }
    for_multiplexing { false }

    # Standard library request type, suitable for most Limber processes
    factory :library_request_type do
      name { 'Limber WGS' }
      key { 'limber_wgs' }
    end

    # Request type for the pooling step at the end of most pipelines
    factory :mx_request_type do
      name { 'Limber Multiplexing' }
      key { 'limber_multiplexing' }
      for_multiplexing { true }
    end

    # Request type for the aggregation
    factory :aggregation_request_type do
      name { 'Limber Bespoke Aggregation' }
      key { 'limber_bespoke_aggregation' }
    end
  end
end
