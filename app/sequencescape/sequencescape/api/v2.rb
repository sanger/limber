# frozen_string_literal: true

# Interface for the json API based Sequencescape V2 api
# Contains query plans
module Sequencescape::Api::V2
  PLATE_PRESENTER_INCLUDES = [
    :purpose,
    { child_plates: :purpose },
    { wells: [
      {
        downstream_tubes: 'purpose',
        requests_as_source: %w[request_type primer_panel pre_capture_pool],
        aliquots: ['sample', { request: %w[request_type primer_panel pre_capture_pool] }],
        qc_results: []
      }
    ] }
  ].freeze

  def self.plate_for_presenter(query)
    Plate.includes(*PLATE_PRESENTER_INCLUDES).find(query).first
  end

  def self.additional_plates_for_presenter(query)
    Plate.includes(*PLATE_PRESENTER_INCLUDES).find(query)
  end

  def self.plate_with_wells(uuid)
    Plate.includes('wells').find(uuid: uuid).first
  end

  def self.plate_for_completion(uuid)
    Plate.includes('wells.aliquots.request.submission,wells.aliquots.request.request_type')
         .find(uuid: uuid)
         .first
  end

  def self.plate_with_custom_includes(include_params, search_params)
    Plate.includes(include_params).find(search_params).first
  end

  # Retrieves results of query builder (JsonApiClient::Query::Builder) page by page
  # and combines them into one list
  def self.merge_page_results(query_builder, page_size)
    all_records = []
    page_num = 1
    num_retrieved = page_size

    # if the final page is a full page (has page_size records),
    # it does one more iteration and you get an empty array retrieved, stopping the loop
    while num_retrieved == page_size
      current_page = query_builder.page(page_num).to_a
      num_retrieved = current_page.size
      all_records += current_page
      page_num += 1
    end

    all_records
  end
end
