# frozen_string_literal: true

require_dependency 'presenters'

module Presenters::Presenter # rubocop:todo Style/Documentation
  extend ActiveSupport::Concern

  included do
    include Form
    include BarcodeLabelsHelper

    class_attribute :summary_items, :sidebar_partial, :summary_partial

    attr_accessor :api, :labware

    self.page = 'show'
    self.sidebar_partial = 'default'
    self.summary_items = []
    self.summary_partial = ''

    def csv
      purpose_config[:csv_template]
    end
  end

  delegate :state, :uuid, :id, :purpose_name, to: :labware

  def suggest_library_passing?
    active_pipelines.any? { |pl| pl.library_pass?(purpose_name) }
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

  def summary
    summary_items.each { |label, method_symbol| yield label, send(method_symbol) }
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

  def child_assets
    nil
  end

  private

  def active_pipelines
    Settings.pipelines.active_pipelines_for(labware)
  end

  def purpose_config
    Settings.purposes.fetch(purpose.uuid, {})
  end

  def stock_plate_barcode_from_metadata(plate_machine_barcode)
    begin
      metadata = LabwareMetadata.new(api: api, barcode: plate_machine_barcode).metadata
    rescue Sequencescape::Api::ResourceNotFound
      metadata = nil
    end
    metadata.present? ? metadata.fetch('stock_barcode', barcode) : 'N/A'
  end
end
