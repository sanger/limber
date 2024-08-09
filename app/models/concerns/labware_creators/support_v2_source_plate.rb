# frozen_string_literal: true

# TODO: {Y24-190} Remove this module once the V1 API is no longer used.

# Can be included in labware creators which require access to a V2 source plate when passing a V1 parent plate
# to methods/classes requiring V2 resources.
module LabwareCreators::SupportV2SourcePlate
  extend ActiveSupport::Concern

  # parent is using SS v1 API
  # so this method is used to access the plate via SS v2 API
  def source_plate
    if parent.is_a? Limber::Plate
      @source_plate ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent.uuid) if @source_plate&.uuid != parent.uuid
    else
      @source_plate = nil
    end

    @source_plate
  end
end
