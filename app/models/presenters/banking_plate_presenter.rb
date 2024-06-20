# frozen_string_literal: true

module Presenters
  # Presenter for the scRNA Core LRC PBMC Bank plate to enable the file links
  # based on the configured plate states.
  class BankingPlatePresenter < StandardPresenter
    include Presenters::Statemachine::FeatureInStates

    # Returns the CSV file links for the plate based on the configured states.
    #
    # @return [Array<Array<String, Array>>] the CSV file links
    def csv_file_links
      links =
        purpose_config
          .fetch(:file_links, [])
          .select { |link| can_be_enabled?(link&.states) }
          .map do |link|
            [
              link.name,
              [
                :limber_plate,
                :export,
                { id: link.id, limber_plate_id: human_barcode, format: :csv, **link.params || {} }
              ]
            ]
          end
      links << ['Download Worksheet CSV', { format: :csv }] if csv.present?
      links
    end
  end
end
