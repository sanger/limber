# frozen_string_literal: true

# Used by the final tube form, siblings describe other tubes
# that are part of the same submission, as well as placeholders
# for tubes which are still due to be created.
class Sibling
  # The state in which a sibling must be to allow pooling.
  READY_STATE = 'passed'

  attr_reader :name, :uuid, :state, :barcode, :sanger_barcode

  def initialize(options)
    if options.respond_to?(:fetch)
      @name = options.fetch('name', 'UNKNOWN')
      @uuid = options.fetch('uuid', nil)
      @barcode = options.fetch('ean13_barcode', 'UNKNOWN')
      @sanger_barcode = SBCF::SangerBarcode.from_machine(options.fetch('ean13_barcode', 'UNKNOWN'))
      @state = options.fetch('state', 'UNKNOWN')
    else
      missing_sibling
    end
  end

  def message
    return 'This tube is ready for pooling, find it, and scan it in above' if state == READY_STATE
    return 'Some requests still need to be progressed to appropriate tubes' if state == 'Not Present'

    "Must be #{READY_STATE.humanize} first"
  end

  def ready?
    state == READY_STATE
  end

  private

  def missing_sibling
    @name = 'Other'
    @state = 'Not Present'
    @sanger_barcode = 'Not Present'
  end
end
