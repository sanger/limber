# frozen_string_literal: true

module Presenters
  module Presenter
    def self.included(base)
      base.class_eval do
        include Forms::Form
        self.page = 'show'

        class_attribute :csv
        self.csv = 'show'
      end
    end

    delegate :state, to: :labware

    def save!
    end

    def purpose_name
      labware.purpose.name
    end

    def title
      purpose_name
    end

    def default_printer_uuid
      @default_printer_uuid ||= Settings.printers[purpose_config.default_printer_type]
    end

    def default_label_count
      @default_label_count ||= Settings.printers['default_count']
    end

    def printer_limit
      @printer_limit ||= Settings.printers['limit']
    end

    def well_failing_applicable?
      well_failure_states.include?(state.to_sym)
    end

    # To get rid!
    def suitable_labware
      yield
    end

    def errors
      nil
    end

    def label_type
      yield 'custom-labels'
      nil
    end

    def prioritized_name(str, max_size)
      # Regular expression to match
      return 'Unnamed' if str.blank?
      match = str.match(/([A-Z]{2})(\d+)([[:alpha:]])( )(\w+)(:)(\w+)/)
      return str if match.nil?
      # Sets the priorities position matches in the regular expression to dump into the final string. They will be
      # performed with preference on the most right characters from the original match string
      priorities = [7, 5, 2, 6, 3, 1, 4]

      # Builds the final string by adding the matching string using the previous priorities list
      priorities.each_with_object([]) do |value, cad_list|
        size_to_copy = max_size - cad_list.join('').length
        text_to_copy = match[value]
        cad_list[value] = (text_to_copy[[0, text_to_copy.length - size_to_copy].max, size_to_copy])
        cad_list
      end.join('')
    end

    def summary
      summary_items.each do |label, method_symbol|
        yield label, send(method_symbol)
      end
    end

    def created_on
      labware.created_at.to_formatted_s(:date_created)
    end

    private

    def purpose_config
      Settings.purposes[purpose.uuid]
    end
  end
end
