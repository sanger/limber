# frozen_string_literal: true

module SearchHelper
  def search_status(search_results)
    if search_results.present?
      'Search Results'
    else
      'No plates found.'
    end
  end

  def stock_plate_uuids
    Settings.purposes.select { |_uuid, config| config.input_plate }.keys
  end
end
