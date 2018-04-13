# frozen_string_literal: true

class Labels::Base
  attr_reader :labware

  def initialize(labware)
    @labware = labware
  end

  def extra_attributes
    {}
  end

  def date_today
    Time.zone.today.strftime('%e-%^b-%Y')
  end

  def printer_type
    purpose_printer_type = Settings.purposes.fetch(labware.purpose.uuid, {}).fetch(:printer_type, nil)
    purpose_printer_type || labware.barcode.type
  end

  def label_template
    purpose_pmb_template = Settings.purposes.fetch(labware.purpose.uuid, {}).fetch(:pmb_template, nil)
    purpose_pmb_template || Settings.default_pmb_template_for_printer[printer_type]
  end
end
