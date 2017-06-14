# frozen_string_literal: true

class Labels::Base
  attr_reader :labware

  def initialize(labware)
    @labware = labware
  end

  def date_today
    Time.zone.today.strftime('%e-%^b-%Y')
  end

  def type
    labware.barcode.type
  end
end
