# frozen_string_literal: true

module Presenters
  # Used for tag plates / tag 2 tubes. Rendered with default to_json behaviour.
  class QcablePresenter
    def initialize(qcable)
      @uuid = qcable.uuid
      @tag_layout = qcable.lot.template_name
      @asset_uuid = qcable.asset.uuid
      @state = qcable.state
      @type = qcable.lot.lot_type_name
      @qcable_type = qcable.lot.lot_type.qcable_name
      @template_uuid = qcable.lot.template.uuid
      @lot_number = qcable.lot.lot_number
    end
  end
end
