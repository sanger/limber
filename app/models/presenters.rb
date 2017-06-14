# frozen_string_literal: true

module Presenters
  def self.lookup_for(labware)
    (presentation_classes = Settings.purposes[labware.plate_purpose.uuid]) || (return UnknownLabwareType)
    presentation_classes[:presenter_class].constantize
  end
end
