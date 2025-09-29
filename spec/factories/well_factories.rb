# frozen_string_literal: true

require './lib/well_helpers'
require_relative '../support/factory_bot_extensions'

FactoryBot.define do
  # V2 well
  factory :well, class: Sequencescape::Api::V2::Well do
    initialize_with { Sequencescape::Api::V2::Well.load(attributes) }

    skip_create

    transient do
      location { 'A1' }
      qc_results { [] }

      # Number of aliquots in the well
      aliquot_count { 1 }

      # The outer request associated with the well via aliquot
      # Use the stock well factory if you want the request comming out of the well
      outer_request { create request_factory, state: library_state }

      study { create :study, name: 'Well Study' }
      project { create :project, name: 'Well Project' }

      # The factory to use for aliquots
      aliquot_factory { :aliquot }
      aliquots do
        # Conditional to avoid generating requests when not required
        aliquot_count.positive? ? create_list(aliquot_factory, aliquot_count, outer_request:, study:, project:) : []
      end

      # The factory to use for outer requests
      request_factory { :library_request }

      # The requests comming out of the well. stock wells will set this based
      # on outer request.
      requests_as_source { [] }

      # Requests terminating at the well. Generally only seen on the final
      # plate of the process after libraries are passed.
      requests_as_target { [] }

      # The state of the ongoing requests.
      library_state { 'pending' }

      # Set up relationships downstream
      # In Sequencescape world these are all populated via the
      # transfer requests
      downstream_tubes { [] }
      downstream_assets { [] }
      downstream_plates { [] }
      upstream_tubes { [] }
      upstream_assets { [] }
      upstream_plates { [] }

      # Plate barcode is used in the well names
      plate_barcode { 'DN1S' }
    end

    uuid

    name { "#{plate_barcode}:#{location}" }
    position { { 'name' => location } }
    state { 'passed' }
    diluent_volume { nil }
    pcr_cycles { nil }
    submit_for_sequencing { nil }
    sub_pool { nil }
    coverage { nil }

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) do |well, evaluator|
      well._cached_relationship(:qc_results) { evaluator.qc_results || [] }
      well._cached_relationship(:aliquots) { evaluator.aliquots || [] }
      well._cached_relationship(:requests_as_source) { evaluator.requests_as_source || [] }
      well._cached_relationship(:requests_as_target) { evaluator.requests_as_target || [] }
      well._cached_relationship(:downstream_tubes) { evaluator.downstream_tubes || [] }
      well._cached_relationship(:downstream_assets) { evaluator.downstream_assets || [] }
      well._cached_relationship(:downstream_plates) { evaluator.downstream_plates || [] }
      well._cached_relationship(:upstream_tubes) { evaluator.upstream_tubes || [] }
      well._cached_relationship(:upstream_assets) { evaluator.upstream_assets || [] }
      well._cached_relationship(:upstream_plates) { evaluator.upstream_plates || [] }
      well._cached_relationship(:pcr_cycles) { evaluator.pcr_cycles || [] }
    end

    # API v2 stock wells associate the outer requests with the well requests_as_source,
    # not the aliquots
    factory :stock_well do
      transient do
        aliquot_factory { :stock_aliquot }
        requests_as_source { [outer_request].compact }
      end
    end

    # Tagged wells have tagged aliquots
    factory :tagged_well do
      transient { aliquot_factory { :tagged_aliquot } }
    end

    # Mock in transfer requests into and out of the well
    factory :well_with_transfer_requests do
      transient do
        transfer_request_as_source_volume { 10.0 }
        transfer_request_as_source_target_asset { :well }
        transfer_requests_as_source do
          [
            create(
              :transfer_request,
              source_asset: nil,
              target_asset: transfer_request_as_source_target_asset,
              volume: transfer_request_as_source_volume
            )
          ]
        end
        transfer_request_as_target_volume { 10.0 }
        transfer_request_as_target_source_asset { :well }
        transfer_requests_as_target do
          [
            create(
              :transfer_request,
              source_asset: transfer_request_as_target_source_asset,
              target_asset: nil,
              volume: transfer_request_as_target_volume
            )
          ]
        end
      end

      after(:build) do |well, evaluator|
        well._cached_relationship(:transfer_requests_as_source) { evaluator.transfer_requests_as_source || [] }
        well._cached_relationship(:transfer_requests_as_target) { evaluator.transfer_requests_as_target || [] }
      end
    end

    factory :well_with_polymetadata do
      transient { poly_metadata { [] } }

      after(:build) do |well, evaluator|
        # initialise the poly_metadata array
        well.poly_metadata = []

        # add each polymetadatum to the well
        evaluator.poly_metadata.each do |pm|
          # set the relationship between the polymetadatum and the well
          pm.relationships.metadatable = well

          # link the polymetadatum to the well
          well.poly_metadata.push(pm)
        end
      end
    end

    factory :well_with_transfer_requests_and_polymetadata, parent: :well do
      transient do
        # From :well_with_transfer_requests
        transfer_request_as_source_volume { 10.0 }
        transfer_request_as_source_target_asset { :well }
        transfer_requests_as_source do
          [
            create(
              :transfer_request,
              source_asset: nil,
              target_asset: transfer_request_as_source_target_asset,
              volume: transfer_request_as_source_volume
            )
          ]
        end

        transfer_request_as_target_volume { 10.0 }
        transfer_request_as_target_source_asset { :well }
        transfer_requests_as_target do
          [
            create(
              :transfer_request,
              source_asset: transfer_request_as_target_source_asset,
              target_asset: nil,
              volume: transfer_request_as_target_volume
            )
          ]
        end

        # From :well_with_polymetadata
        poly_metadata { [] }
      end

      after(:build) do |well, evaluator|
        # Transfer request relationships
        well._cached_relationship(:transfer_requests_as_source) { evaluator.transfer_requests_as_source || [] }
        well._cached_relationship(:transfer_requests_as_target) { evaluator.transfer_requests_as_target || [] }

        # Poly metadata setup
        well.poly_metadata = []

        evaluator.poly_metadata.each do |pm|
          pm.relationships.metadatable = well
          well.poly_metadata.push(pm)
        end
      end
    end
  end

  # API V2 aliquot
  factory :aliquot, class: Sequencescape::Api::V2::Aliquot do
    initialize_with { Sequencescape::Api::V2::Aliquot.load(attributes) }

    transient do
      # State of the ongoing library request
      library_state { 'pending' }

      # Alias for request: The request set on the aliquot itself
      outer_request { create :library_request, state: library_state }
      well_location { 'A1' }
      study { create :study, name: 'Test Aliquot Study' }
      project { create :project, name: 'Test Aliquot Project' }
      sample_attributes { {} }
    end

    sequence(:id, &:to_s)
    tag_oligo { nil }
    tag_index { nil }
    tag2_oligo { nil }
    tag2_index { nil }
    suboptimal { false }
    sample { create :sample, sample_attributes }
    request { outer_request }

    # See the README.md for an explanation under "FactoryBot is not mocking my related resources correctly"
    after(:build) do |aliquot, evaluator|
      Sequencescape::Api::V2::Aliquot.associations.each do |association|
        aliquot._cached_relationship(association.attr_name) { evaluator.send(association.attr_name) }
      end

      aliquot.relationships.study = {
        'links' => {
          'self' => "http://localhost:3000/api/v2/aliquots/#{aliquot.id}/relationships/study",
          'related' => "http://localhost:3000/api/v2/aliquots/#{aliquot.id}/study"
        },
        'data' => {
          'type' => 'studies',
          'id' => evaluator.study.id.to_s
        }
      }
      aliquot.relationships.project = {
        'links' => {
          'self' => "http://localhost:3000/api/v2/aliquots/#{aliquot.id}/relationships/project",
          'related' => "http://localhost:3000/api/v2/aliquots/#{aliquot.id}/project"
        },
        'data' => {
          'type' => 'projects',
          'id' => evaluator.project.id.to_s
        }
      }
    end

    factory :tagged_aliquot do
      sequence(:tag_oligo) { |i| i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G') }
      tag_index { |_i| (WellHelpers.column_order.index(well_location) || 0) + 1 }
      sequence(:tag2_oligo) { |i| i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G') }
      tag2_index { |_i| (WellHelpers.column_order.index(well_location) || 0) + 1 }
    end

    factory :tagged_aliquot_for_mbrave do
      sequence(:tag_oligo) { |i| i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G') }
      tag_index { |_i| (WellHelpers.column_order.index(well_location) || 0) + 1 }
      sequence(:tag2_oligo) { |i| i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G') }
      tag2_index { |_i| (WellHelpers.column_order.index(well_location) || 0) + 1 }
      tag { create(:tag, tag_group: create(:tag_group, name: 'Bioscan_forward_96_v2')) }
      tag2 { |_i| create(:tag, tag_group: create(:tag_group, name: 'Bioscan_reverse_4_1_v2')) }

      sample { create(:sample, sample_metadata: create(:sample_metadata_for_mbrave)) }
    end

    factory :suboptimal_aliquot do
      suboptimal { true }
    end

    # V2 API stock aliquots. Prevents the request being set on aliquot
    factory :stock_aliquot do
      request { nil }
    end

    skip_create
  end
end
