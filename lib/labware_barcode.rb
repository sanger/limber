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

  def to_s
    @human
  end

  #
  # Match operator. Checks to see if the other barcode, is a match for this one.
  # - In the case of foreign barcodes we match only when the other barcode is equal to the machine_barcode
  # - In the case of SBCF formatted barcodes (eg DN1234K/1220001234757) we delegate to the matcher in SBCF::SangerBarcode
  #   This allows us to match either ean13 or code39 formatted barcodes (or the machine barcode to human readable
  #   version in the case of older plates).
  #
  # @param other [String] The barcode to check
  #
  # @return [Bool] True is the barcodes match, false otherwise.
  #
  def =~(other)
    sbcf.valid? ? sbcf =~ other : machine == other
  end

  private

  def sbcf
    @sbcf ||= SBCF::SangerBarcode.from_human(@human)
  end

  def extracted
    /\A(?<prefix>[a-zA-Z]*)-?(?<number>\d+)/.match(human)
  end
end
