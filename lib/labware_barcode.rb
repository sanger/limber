# frozen_string_literal: true

# Wraps labware barcodes to assist with rendering and to provide a cleaner interface
class LabwareBarcode
  attr_reader :human, :machine, :ean13

  def initialize(human:, machine:, ean13: nil)
    @human = human
    @machine = machine
    @ean13 = ean13
  end

  def number
    extracted && extracted[:number]
  end

  def prefix
    extracted && extracted[:prefix]
  end

  private

  def extracted
    /\A(?<prefix>[a-zA-Z]*)(?<number>\d+)/.match(human)
  end
end
