# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  factory :request, class: Sequencescape::Api::V2::Request, traits: [:uuid] do
    transient do
      pcr_cycles 10
      sequence(:submission_id) { |i| i }
    end

    skip_create
    sequence(:id, &:to_s)
    role 'WGS'
    priority 0
    state 'pending'
    options do
      {
        'pcr_cycles' => pcr_cycles
      }
    end
    request_type { create :request_type }
    primer_panel nil
    pre_capture_pool nil

    after(:build) do |request, evaluator|
      request.relationships.submission = {
        'links' => {
          'self' => "http://localhost:3000/api/v2/requests/#{request.id}/relationships/submission",
          'related' => "http://localhost:3000/api/v2/requests/#{request.id}/submission"
        },
        'data' => { 'type' => 'submissions', 'id' => evaluator.submission_id.to_s }
      }
    end

    factory :library_request do
      request_type { create :library_request_type }

      factory :gbs_library_request do
        primer_panel
      end

      factory :isc_library_request do
        pre_capture_pool
      end
    end

    factory :mx_request do
      request_type { create :mx_request_type }
    end
  end

  factory :primer_panel, class: Sequencescape::Api::V2::PrimerPanel do
    skip_create

    name 'example panel'
    programs('pcr 1' => { 'name' => 'example program', 'duration' => 45 },
             'pcr 2' => { 'name' => 'other program', 'duration' => 20 })
  end

  factory :pre_capture_pool, class: Sequencescape::Api::V2::PreCapturePool do
    skip_create
    id 1
    uuid 'pre-capture-pool'
  end

  factory :request_type, class: Sequencescape::Api::V2::RequestType do
    skip_create
    name 'Request Type'
    key 'request_type'
    for_multiplexing false

    factory :library_request_type do
      name 'Limber WGS'
      key 'limber_wgs'
    end

    factory :mx_request_type do
      name 'Limber Multiplexing'
      key 'limber_multiplexing'
      for_multiplexing true
    end
  end
end
