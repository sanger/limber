# frozen_string_literal: true

module Presenters
  def self.lookup_for(labware)
    presentation_classes = Settings.purposes[labware.plate_purpose.uuid]
    if presentation_classes
      presentation_classes[:presenter_class].constantize
    else
      case labware
      when Limber::Plate then Presenters::UnknownPlatePresenter
      when Limber::Tube then Presenters::UnknownTubePresenter
      else raise UnknownLabwareType
      end
    end
  end
end
