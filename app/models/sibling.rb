# frozen_string_literal: true

# Used by the final tube form, siblings describe other tubes
# that are part of the same submission, as well as placeholders
# for tubes which are still due to be created.
class Sibling
  # The state in which a sibling must be to allow pooling.
  READY_STATE = 'passed'

  attr_reader :name, :uuid, :state, :barcode

  def initialize(options)
    if options.respond_to?(:[])
      @name = options['name']
      @uuid = options['uuid']
      @barcode = options['ean13_barcode']
      @state = options['state']
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
    @name  = 'Other'
    @state = 'Not Present'
  end
end
