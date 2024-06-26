# frozen_string_literal: true

module Presenters
  #
  # The StandardPresenter is used for the majority of plates. It shows a preview
  # of the plate itself, and permits state changes, well failures and child
  # creation when passed.
  #
  class StandardPresenter < PlatePresenter
    include Presenters::Statemachine::Standard

    validates_with Validators::SuboptimalValidator
    validates_with Validators::ActiveRequestValidator

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
