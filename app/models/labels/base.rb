# frozen_string_literal: true

class Labels::Base # rubocop:todo Style/Documentation
  attr_reader :labware

  # Generates a label object for the provided labware
  # @param labware [Labware] The tube or plate for which to generate a label
  # @param options = {} [Hash] Optional parameters hash
  def initialize(labware, options = {})
    @labware = labware
    @options = options
  end

  def extra_attributes
    {}
  end

  def intermediate_attributes
    []
  end

  def qc_attributes
    []
  end

  def sprint_attributes
    attributes
  end

  def date_today
    Time.zone.today.strftime('%e-%^b-%Y')
  end

  delegate :workline_identifier, to: :labware

  def printer_type
    config.fetch(:printer_type, default_printer_type)
  end

  def label_template
    config.fetch(:pmb_template, default_label_template)
  end

  def label_templates_by_service
    pmb_template = config.fetch(:pmb_template, default_label_template)
    sprint_template = config.fetch(:sprint_template, default_sprint_label_template)
    { 'PMB' => pmb_template, 'SPrint' => sprint_template }
  end

  private

  def config
    @config ||= Settings.purposes.fetch(labware.purpose&.uuid, {})
  end

  def default_printer_type_for(printer_type)
    Settings.default_printer_type_names[printer_type]
  end

  def default_label_template_for(printer_type)
    Settings.default_pmb_templates[printer_type]
  end

  def default_sprint_label_template_for(printer_type)
    Settings.default_sprint_templates[printer_type]
  end
end
