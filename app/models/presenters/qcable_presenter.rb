module Presenters
  class QcablePresenter

    def initialize(qcable)
      @uuid = qcable.uuid
      @tag_layout = qcable.lot.template_name
      @asset_uuid = qcable.asset.uuid
      @state = qcable.state
      @type = qcable.lot.lot_type_name
      @template_uuid = qcable.lot.template.uuid
      @lot_number = qcable.lot.lot_number
    end

  end
end
