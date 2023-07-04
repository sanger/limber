# frozen_string_literal: true

module Presenters
    # Plate type 'Tag Plate - 384' is not a Limber plate because it is not in pipeline purpose config.
    # This presenter enables printing barcode labels from within Limber using the 384-well plate single label template.
    class TagPlate384Presenter < UnknownPlatePresenter
        def label
            Labels::Plate384SingleLabel.new(labware)
        end
    end
end