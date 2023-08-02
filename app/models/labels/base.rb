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

  # Returns printer type name for the label. It is configured for label
  # definitions in label_templates.yml and corresponds to one of the values
  # in name column of barcode_printer_types table in sequencescape database.
  def printer_type
    # NB. We are using short-circuit-or to avoid unnecessary method evaluation
    # instead of Hash.fetch with the default argument as a method call.
    config[:printer_type] || default_printer_type
  end

  def label_template
    # NB. We are using short-circuit-or to avoid unnecessary method evaluation
    # instead of Hash.fetch with the default argument as a method call.
    config[:pmb_template] || default_label_template
  end

  def label_templates_by_service
    # NB. Make sure label_templates.yml contains settings for label definitions
    # explicity, in order to avoid incorrect results. The lines below do not 
    # work as intended because the config is filled with default values for 
    # missing settings by PurposeConfig class.
    pmb_template = config[:pmb_template] || default_label_template
    sprint_template = config[:sprint_template] || default_sprint_label_template
    { 'PMB' => pmb_template, 'SPrint' => sprint_template }
  end

  private

  def config
    @config ||= Settings.purposes.fetch(labware.purpose&.uuid, {})
  end

  # NB. The argument in the following methods was renamed from "printer_type" 
  # to "key" to avoid confusion. It can be one of the keys in 
  # default_printer_type_names section of label_templates.yml config file.
  # It is used for accessing an option for a printer type in default_* 
  # sections. 

  def default_printer_type_for(key)
    Settings.default_printer_type_names[key]
  end

  def default_label_template_for(key)
    Settings.default_pmb_templates[key]
  end

  def default_sprint_label_template_for(key)
    Settings.default_sprint_templates[key]
  end
end
