# frozen_string_literal: true

require_dependency 'presenters'
module Presenters
  module Presenter
    extend ActiveSupport::Concern

    included do
      include Form
      include BarcodeLabelsHelper

      class_attribute :summary_items

      attr_accessor :api, :labware

      self.page = 'show'
      #     self.attributes = %i[api labware]

      def csv
        purpose_config[:csv_template]
      end
    end

    delegate :state, :uuid, to: :labware

    def suggest_library_passing?
      (purpose_config[:suggest_library_pass_for] & passable_request_types).present?
    end

    def purpose_name
      labware.purpose.name
    end

    def title
      purpose_name
    end

    def default_printer
      @default_printer ||= Settings.printers[purpose_config.default_printer_type]
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

    def summary
      summary_items.each do |label, method_symbol|
        yield label, send(method_symbol)
      end
      nil
    end

    # Human formatted date of creation
    #
    # @return [String] Human formatted date of creation
    def created_on
      labware.created_at.to_formatted_s(:date_created)
    end

    # Formatted barcode string for display
    #
    # @return [String] Barcode string. eg. DN1 12200000123
    def barcode
      useful_barcode(labware.barcode)
    end

    # Formatted stock plate barcode string for display
    #
    # @return [String] Barcode string. eg. DN1 12200000123
    def input_barcode
      useful_barcode(labware.stock_plate.try(:barcode))
    end

    def inspect
      "<#{self.class.name} labware:#{labware.uuid} ...>"
    end

    private

    def purpose_config
      Settings.purposes.fetch(purpose.uuid, {})
    end
  end
end
