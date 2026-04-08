# frozen_string_literal: true

module Presenters
  # Used for tag plates / tag 2 tubes. Rendered with default to_json behaviour.
  class QcablePresenter
    def initialize(qcable)
      init_qcable_attributes(qcable)
      init_lot_attributes(qcable.lot)
      init_lot_type_attributes(qcable.lot.lot_type)
      init_template_attributes(qcable.lot.template)
    end

    def init_qcable_attributes(qcable)
      @asset_uuid = qcable.labware.uuid
      @state = qcable.state
      @uuid = qcable.uuid
    end

    def init_lot_attributes(lot)
      @lot_number = lot.lot_number
    end

    def init_lot_type_attributes(lot_type)
      @qcable_type = lot_type.target_purpose.name
      @type = lot_type.name
    end

    def init_template_attributes(template)
      @tag_layout = template.name
      @template_uuid = template.uuid
    end
  end
end
