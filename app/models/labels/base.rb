# frozen_string_literal: true

class Labels::Base
  attr_reader :labware

  #
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

  def date_today
    Time.zone.today.strftime('%e-%^b-%Y')
  end

  def printer_type
    Settings.purposes.fetch(labware.purpose.uuid, {}).fetch(:printer_type, default_printer_type)
  end

  def label_template
    Settings.purposes.fetch(labware.purpose.uuid, {}).fetch(:pmb_template, default_label_template)
  end

  private

  def default_printer_type_for(printer_type)
    Settings.default_printer_type_names[printer_type]
  end

  def default_label_template_for(printer_type)
    Settings.default_pmb_templates[printer_type]
  end
end
