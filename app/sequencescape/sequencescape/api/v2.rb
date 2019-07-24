# frozen_string_literal: true

# Interface for the json API based Sequencescape V2 api
# Contains query plans
module Sequencescape::Api::V2
  PLATE_PRESENTER_INCLUDES = [
    :purpose,
    { child_plates: :purpose },
    { wells: [
      :downstream_tubes,
      {
        requests_as_source: %w[request_type primer_panel pre_capture_pool],
        aliquots: ['sample', { request: %w[request_type primer_panel pre_capture_pool] }]
      }
    ] }
  ].freeze

  def self.plate_for_presenter(query)
    Plate.includes(*PLATE_PRESENTER_INCLUDES).find(query).first
  end

  def self.plate_with_wells(uuid)
    Plate.includes('wells').find(uuid: uuid).first
  end

  def self.plate_for_completion(uuid)
    Plate.includes('wells.aliquots.request.submission')
         .select(
           submissions: 'uuid',
           plates: 'uuid,wells',
           aliquots: 'request',
           requests: 'submission',
           wells: 'aliquots'
         )
         .find(uuid: uuid)
         .first
  end

  def self.plate_with_custom_includes(include_params, search_params)
    Plate.includes(include_params).find(search_params).first
  end
end
