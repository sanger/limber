#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
module Presenters
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
