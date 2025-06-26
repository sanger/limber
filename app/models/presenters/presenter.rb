# frozen_string_literal: true

require_dependency 'presenters'

module Presenters::Presenter # rubocop:todo Style/Documentation
  extend ActiveSupport::Concern

  included do
    include Form
    include BarcodeLabelsHelper
    include Presenters::Statemachine::FeatureInStates # provides the can_be_enabled?(states) method

    class_attribute :summary_items, :sidebar_partial, :summary_partial, :pooling_tab

    attr_accessor :labware, :info_messages

    self.page = 'show'
    self.sidebar_partial = 'default'
    self.summary_items = []
    self.summary_partial = ''
    self.pooling_tab = ''

    def csv
      purpose_config[:csv_template]
    end
  end

  delegate :state, :uuid, :id, :purpose_name, to: :labware

  def initialize(*args)
    super
    @info_messages = []
    return unless defined?(purpose) && purpose.respond_to?(:uuid)

    presenter_class_config = purpose_config[:presenter_class]
    return unless presenter_class_config.is_a?(Hash)

    messages = presenter_class_config.dig(:args, :messages)
    @info_messages.concat(messages) if messages
  end

  def suggest_library_passing?
    active_pipelines.any? { |pl| pl.library_pass?(purpose_name) }
  end

  # Generates a formatted title for the labware as seen in the HTML document title.
  #
  # Combines the purpose name and human-readable barcode, if available.
  # @return [String] Formatted title, e.g., "Tube Purpose (NT1234)".
  def document_title
    human_barcode ? "#{purpose_name} (#{human_barcode})" : purpose_name
  end

  # Generates the content title for the labware as seen in the page.
  def content_title
    purpose_name
  end

  def default_printer
    @default_printer ||= Settings.printers[purpose_config.default_printer_type]
  end

  def default_label_count
    @default_label_count ||= Settings.printers[:default_count]
  end

  def printer_limit
    @printer_limit ||= Settings.printers[:limit]
  end

  def summary
    summary_items.each { |label, method_symbol| yield label, send(method_symbol) }
  end

  # Human formatted date of creation
  #
  # @return [String] Human formatted date of creation
  def created_on
    labware.created_at.to_fs(:date_created)
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

  # A collection of parents for this labware including purposes.
  # Returns an empty array if there are no parents.
  #
  # @return [Array<Sequencescape::Api::V2::Labware>] Array of parent labwares with purposes.
  def parent_labwares
    parents = labware.parents || []
    parent_uuids = parents.compact.map(&:uuid).uniq
    return [] if parent_uuids.empty?

    parent_labwares = Sequencescape::Api::V2::Labware.find_all({ uuid: parent_uuids }, includes: %w[purpose])

    # some old or 'lane' labwares may not have a purpose, so filter those out
    parent_labwares.filter { |labware| labware.purpose.present? }
  end

  # A collection of child labwares for this labware including purposes.
  # Returns an empty array if there are no children.
  #
  # @return [Array<Sequencescape::Api::V2::Labware>] Array of child labwares with purposes.
  def child_labwares
    children = labware.children || []
    child_uuids = children.compact.map(&:uuid).uniq
    return [] if child_uuids.empty?

    child_labwares = Sequencescape::Api::V2::Labware.find_all({ uuid: child_uuids }, includes: %w[purpose])

    # some old or 'lane' labwares may not have a purpose, so filter those out
    child_labwares.filter { |labware| labware.purpose.present? }
  end

  def child_assets
    nil
  end

  # Determine if we should display the pooling tab in the Presenter views
  # See partial _common_tabbed_pages.html.erb
  # Overridden in the PlatePresenter
  def show_pooling_tab?
    # if pooling_tab field is present, show the tab (allows override)
    return true if pooling_tab.present?

    # do not show the pooling tab by default
    false
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
      metadata = LabwareMetadata.new(barcode: plate_machine_barcode).metadata
    rescue Sequencescape::Api::ResourceNotFound
      metadata = nil
    end
    metadata.present? ? metadata.fetch('stock_barcode', barcode) : 'N/A'
  end
end
