# frozen_string_literal: true

module Presenters
  def self.lookup_for(labware)
    presentation_classes = Settings.purposes[labware.purpose.uuid]

    if presentation_classes
      presentation_classes[:presenter_class].constantize
    else
      return Presenters::UnknownPlatePresenter if labware.plate?
      return Presenters::UnknownTubePresenter if labware.tube?

      raise UnknownLabwareType
    end
  end
end
