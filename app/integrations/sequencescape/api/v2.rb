# frozen_string_literal: true

# Interface for the json API based Sequencescape V2 api
# Contains query plans
# :reek:UncommunicativeModuleName
module Sequencescape::Api::V2
  SsApiV2 = Sequencescape::Api::V2

  # transfer_request_as_target.source_asset is added to the includes to make
  # the source receptacles available in presenters.
  PLATE_PRESENTER_INCLUDES = [
    :purpose,
    { child_plates: :purpose },
    {
      wells: [
        :qc_results,
        {
          downstream_tubes: 'purpose',
          requests_as_source: %w[request_type primer_panel pre_capture_pool submission],
          aliquots: ['sample.sample_metadata',
                     { request: %w[request_type primer_panel pre_capture_pool submission poly_metadata] }],
          transfer_requests_as_target: %w[source_asset]
        }
      ]
    }
  ].freeze

  # NB. a receptacle can have many aliquots, and aliquot.request is an array (for some reason)
  # Sequencescape::Api::V2::TubeRack.last.racked_tubes.first.tube.receptacle.aliquots.first.request.first.request_type
  TUBE_RACK_PRESENTER_INCLUDES = [
    :purpose,
    { racked_tubes: [{ tube: [:purpose, { receptacle: [{ aliquots: [{ request: [:request_type] }] }] }] }] }
  ].freeze

  #
  # Returns a {Sequencescape::Api::V2::Labware} object with *just* the UUID, suitable for redirection
  #
  # @param barcode [String] The barcode to find
  #
  # @return [Sequencescape::Api::V2::Labware] Found labware object
  #
  def self.minimal_labware_by_barcode(barcode, select: :uuid)
    Sequencescape::Api::V2::Labware.where(barcode:).select(tube_racks: select, plates: select, tubes: select).first
  end

  # sample_description added into includes here for use in bioscan plate label creation
  # multiplexed? added into includes here is used for deciding if the pooling tab should be shown
  def self.plate_for_presenter(query)
    Plate
      .includes(*PLATE_PRESENTER_INCLUDES)
      .select(
        submissions: %w[lanes_of_sequencing multiplexed?],
        sample_metadata: %w[sample_common_name collected_by sample_description]
      )
      .find(query)
      .first
  end

  def self.additional_plates_for_presenter(query)
    Plate.includes(*PLATE_PRESENTER_INCLUDES).find(query)
  end

  def self.plate_with_wells(uuid)
    Plate.includes('wells').find(uuid:).first
  end

  def self.tube_rack_for_presenter(query)
    TubeRack.includes(*TUBE_RACK_PRESENTER_INCLUDES).find(query).first
  end

  def self.plate_for_completion(uuid)
    Plate.includes('wells.aliquots.request.submission,wells.aliquots.request.request_type').find(uuid:).first
  end

  def self.tube_for_completion(uuid)
    Tube.includes('receptacle.aliquots.request.submission,receptacle.aliquots.request.request_type').find(uuid:).first
  end

  def self.tube_rack_for_completion(uuid)
    TubeRack
      .includes(
        'racked_tubes.tube.receptacle.aliquots.request.submission,tube_receptacles.aliquots.request.request_type'
      )
      .find(uuid:)
      .first
  end

  def self.plate_with_custom_includes(include_params, search_params)
    Plate.includes(include_params).find(search_params).first
  end

  def self.tube_with_custom_includes(include_params, select_params, search_params)
    Tube.includes(include_params).select(select_params).find(search_params).first
  end

  def self.tube_rack_with_custom_includes(include_params, select_params, search_params)
    TubeRack.includes(include_params).select(select_params).find(search_params).first
  end

  # Retrieves results of query builder (JsonApiClient::Query::Builder) page by page
  # and combines them into one list
  def self.merge_page_results(query_builder)
    total_pages = query_builder.pages.total_pages
    first_page = query_builder.to_a.dup
    (2..total_pages).reduce(first_page) do |all_pages, page_number|
      current_page = query_builder.page(page_number).to_a
      all_pages.concat(current_page)
    end
  end
end
